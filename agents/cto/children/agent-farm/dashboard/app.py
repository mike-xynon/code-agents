"""
Claude Worker Dashboard
Flask application for managing Claude Code worker containers
"""

import os
import json
import time
import uuid
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for

import docker
from docker.errors import NotFound, APIError

app = Flask(__name__)

# Docker client
docker_client = docker.from_env()

# Configuration
WORKER_IMAGE = os.environ.get('WORKER_IMAGE', 'claude-worker:latest')
NETWORK_NAME = os.environ.get('NETWORK_NAME', 'claude-farm-network')
SHARED_REPOS_VOLUME = os.environ.get('SHARED_REPOS_VOLUME', 'claude-farm-repos')
SHARED_STATE_VOLUME = os.environ.get('SHARED_STATE_VOLUME', 'claude-farm-state')
ANTHROPIC_API_KEY = os.environ.get('ANTHROPIC_API_KEY', '')
BASE_PORT = int(os.environ.get('BASE_PORT', '7681'))
MAX_WORKERS = int(os.environ.get('MAX_WORKERS', '20'))
NGINX_HOST = os.environ.get('NGINX_HOST', 'localhost')
NGINX_PORT = os.environ.get('NGINX_PORT', '8080')
SSH_SECRETS_HOST_PATH = os.environ.get('SSH_SECRETS_HOST_PATH', '')
API_SECRETS_HOST_PATH = os.environ.get('API_SECRETS_HOST_PATH', '')

# In-memory worker registry (could be replaced with Redis)
workers = {}


def sanitize_name(name):
    """Sanitize name for use as Docker container name and worker ID"""
    # Docker container names must match [a-zA-Z0-9][a-zA-Z0-9_.-]
    import re
    sanitized = name.lower().replace(' ', '-')
    sanitized = re.sub(r'[^a-z0-9_.-]', '', sanitized)
    return sanitized or 'worker'


def get_container_name(worker_id):
    """Generate container name from worker ID"""
    return f"claude-worker-{worker_id}"


def get_available_port():
    """Find an available port for a new worker"""
    used_ports = set()
    for worker in workers.values():
        used_ports.add(worker.get('port', 0))

    for port in range(BASE_PORT, BASE_PORT + MAX_WORKERS):
        if port not in used_ports:
            return port

    raise Exception("No available ports")


def sync_workers_from_docker():
    """Sync worker registry with actual Docker containers"""
    global workers

    try:
        containers = docker_client.containers.list(all=True, filters={'name': 'claude-worker-'})

        # Update registry based on actual containers
        current_ids = set()
        for container in containers:
            # Extract worker_id from container name
            name = container.name
            if name.startswith('claude-worker-'):
                worker_id = name.replace('claude-worker-', '')
                current_ids.add(worker_id)

                # Get port mapping
                port = None
                if container.status == 'running':
                    ports = container.attrs.get('NetworkSettings', {}).get('Ports', {})
                    if '7681/tcp' in ports and ports['7681/tcp']:
                        port = int(ports['7681/tcp'][0]['HostPort'])

                # Get environment variables
                env_vars = container.attrs.get('Config', {}).get('Env', [])
                git_repo = ''
                worker_name = ''
                for env in env_vars:
                    if env.startswith('GIT_REPO_URL='):
                        git_repo = env.replace('GIT_REPO_URL=', '')
                    elif env.startswith('WORKER_NAME='):
                        worker_name = env.replace('WORKER_NAME=', '')

                # Use WORKER_NAME if available, otherwise derive from container name
                display_name = worker_name or worker_id
                # Capitalize for display (nuget -> Nuget, registry-web -> Registry-Web)
                display_name = '-'.join(word.capitalize() for word in display_name.split('-'))

                # Update or create worker entry
                if worker_id not in workers:
                    workers[worker_id] = {
                        'id': worker_id,
                        'name': display_name,
                        'status': container.status,
                        'port': port,
                        'git_repo': git_repo,
                        'created_at': container.attrs.get('Created', ''),
                        'container_id': container.id
                    }
                else:
                    workers[worker_id]['status'] = container.status
                    workers[worker_id]['port'] = port
                    workers[worker_id]['container_id'] = container.id
                    # Preserve name if already set, otherwise update
                    if not workers[worker_id].get('name') or workers[worker_id]['name'].startswith('Worker '):
                        workers[worker_id]['name'] = display_name

        # Remove workers that no longer have containers
        for worker_id in list(workers.keys()):
            if worker_id not in current_ids:
                del workers[worker_id]

    except Exception as e:
        print(f"Error syncing workers: {e}")


def create_worker(worker_id, name=None, git_repo_url=''):
    """Create a new Claude worker container"""
    # Use sanitized name as the worker_id for cleaner container names
    # e.g., name="Nuget" -> worker_id="nuget" -> container="claude-worker-nuget"
    if name:
        worker_id = sanitize_name(name)

    container_name = get_container_name(worker_id)
    port = get_available_port()

    # Check if container already exists
    try:
        existing = docker_client.containers.get(container_name)
        existing.remove(force=True)
    except NotFound:
        pass

    # Use sanitized name for repo directory (allows reuse across restarts)
    repo_dir_name = worker_id

    # Create container
    container = docker_client.containers.run(
        WORKER_IMAGE,
        name=container_name,
        detach=True,
        environment={
            'WORKER_ID': worker_id,
            'WORKER_NAME': repo_dir_name,
            'GIT_REPO_URL': git_repo_url,
            'ANTHROPIC_API_KEY': ANTHROPIC_API_KEY,
        },
        ports={'7681/tcp': port},
        volumes={
            SHARED_REPOS_VOLUME: {'bind': '/shared/repos', 'mode': 'rw'},
            SHARED_STATE_VOLUME: {'bind': '/shared/state', 'mode': 'rw'},
            **({SSH_SECRETS_HOST_PATH: {'bind': '/secrets/ssh', 'mode': 'ro'}} if SSH_SECRETS_HOST_PATH else {}),
            **({API_SECRETS_HOST_PATH: {'bind': '/secrets/api', 'mode': 'ro'}} if API_SECRETS_HOST_PATH else {}),
        },
        network=NETWORK_NAME,
        labels={
            'claude-farm': 'worker',
            'worker-id': worker_id,
        },
        restart_policy={'Name': 'unless-stopped'},
    )

    # Register worker with capitalized display name
    display_name = '-'.join(word.capitalize() for word in worker_id.split('-'))
    workers[worker_id] = {
        'id': worker_id,
        'name': display_name,
        'status': 'starting',
        'port': port,
        'git_repo': git_repo_url,
        'created_at': datetime.utcnow().isoformat(),
        'container_id': container.id
    }

    return workers[worker_id]


def stop_worker(worker_id):
    """Stop and remove a worker container"""
    container_name = get_container_name(worker_id)

    try:
        container = docker_client.containers.get(container_name)
        container.stop(timeout=10)
        container.remove()
    except NotFound:
        pass

    if worker_id in workers:
        del workers[worker_id]


def restart_worker(worker_id):
    """Restart a worker container"""
    container_name = get_container_name(worker_id)

    try:
        container = docker_client.containers.get(container_name)
        container.restart(timeout=10)
        workers[worker_id]['status'] = 'restarting'
    except NotFound:
        pass


# Routes

@app.route('/')
def index():
    """Main dashboard page"""
    sync_workers_from_docker()
    return render_template('index.html',
                         workers=list(workers.values()),
                         nginx_host=NGINX_HOST,
                         nginx_port=NGINX_PORT)


@app.route('/api/workers', methods=['GET'])
def list_workers():
    """List all workers"""
    sync_workers_from_docker()
    return jsonify(list(workers.values()))


@app.route('/api/workers', methods=['POST'])
def create_worker_api():
    """Create a new worker"""
    data = request.get_json() or {}

    name = data.get('name')
    git_repo = data.get('git_repo', '')

    # If no name provided, generate one from ID or random
    if not name:
        worker_id = data.get('id') or str(uuid.uuid4())[:12]
        name = f"Worker-{worker_id[:8]}"

    try:
        worker = create_worker(None, name, git_repo)
        return jsonify(worker), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/workers/<worker_id>', methods=['GET'])
def get_worker(worker_id):
    """Get worker details"""
    sync_workers_from_docker()

    if worker_id in workers:
        return jsonify(workers[worker_id])
    return jsonify({'error': 'Worker not found'}), 404


@app.route('/api/workers/<worker_id>', methods=['DELETE'])
def delete_worker(worker_id):
    """Delete a worker"""
    try:
        stop_worker(worker_id)
        return jsonify({'status': 'deleted'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/workers/<worker_id>/restart', methods=['POST'])
def restart_worker_api(worker_id):
    """Restart a worker"""
    try:
        restart_worker(worker_id)
        return jsonify({'status': 'restarting'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/workers/<worker_id>/pull', methods=['POST'])
def pull_worker_api(worker_id):
    """Pull latest code in a worker"""
    container_name = get_container_name(worker_id)

    try:
        container = docker_client.containers.get(container_name)
        # Execute git pull in the worker
        exit_code, output = container.exec_run(
            'su - claude -c "cd /workspace && git pull"',
            demux=True
        )
        stdout = output[0].decode() if output[0] else ''
        stderr = output[1].decode() if output[1] else ''
        return jsonify({
            'status': 'pulled' if exit_code == 0 else 'error',
            'output': stdout,
            'error': stderr
        })
    except NotFound:
        return jsonify({'error': 'Worker not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/bootstrap', methods=['POST'])
def bootstrap_api():
    """Create workers for all repos in repos.json"""
    repos_file = os.environ.get('REPOS_FILE', '/app/repos.json')

    if not os.path.exists(repos_file):
        return jsonify({'error': f'repos.json not found at {repos_file}'}), 404

    try:
        with open(repos_file, 'r') as f:
            config = json.load(f)

        results = []
        sync_workers_from_docker()
        # Check by sanitized name (which is now the worker_id)
        existing_ids = set(workers.keys())

        for repo in config.get('repositories', []):
            name = repo.get('name')
            git_url = repo.get('git_url')
            sanitized = sanitize_name(name)

            if sanitized in existing_ids:
                results.append({'name': name, 'status': 'exists', 'id': sanitized})
                continue

            try:
                worker = create_worker(None, name, git_url)
                results.append({'name': name, 'status': 'created', 'id': worker['id']})
                time.sleep(1)  # Small delay between creations
            except Exception as e:
                results.append({'name': name, 'status': 'error', 'error': str(e)})

        return jsonify({'results': results})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/repos', methods=['GET'])
def list_repos():
    """List configured repositories"""
    repos_file = os.environ.get('REPOS_FILE', '/app/repos.json')

    if not os.path.exists(repos_file):
        return jsonify({'error': 'repos.json not found'}), 404

    with open(repos_file, 'r') as f:
        config = json.load(f)

    return jsonify(config.get('repositories', []))


@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'workers': len(workers)})


if __name__ == '__main__':
    # Sync on startup
    sync_workers_from_docker()

    # Run development server
    app.run(host='0.0.0.0', port=5000, debug=True)
