-- Claude Worker Farm Database Schema
-- Optional PostgreSQL schema for audit logging and task management

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Worker state table
CREATE TABLE IF NOT EXISTS workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    port INTEGER,
    git_repo TEXT,
    container_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Index for quick lookups
CREATE INDEX idx_workers_status ON workers(status);
CREATE INDEX idx_workers_worker_id ON workers(worker_id);

-- Task queue table (for future task distribution)
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID REFERENCES workers(id),
    task_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    result JSONB,
    error TEXT
);

-- Indexes for task queue
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_worker_id ON tasks(worker_id);
CREATE INDEX idx_tasks_priority_created ON tasks(priority DESC, created_at ASC);

-- Audit log table
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL,
    worker_id UUID REFERENCES workers(id),
    user_ip INET,
    user_agent TEXT,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for audit queries
CREATE INDEX idx_audit_log_event_type ON audit_log(event_type);
CREATE INDEX idx_audit_log_worker_id ON audit_log(worker_id);
CREATE INDEX idx_audit_log_created_at ON audit_log(created_at DESC);

-- Session tracking table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    worker_id UUID REFERENCES workers(id),
    session_id VARCHAR(100) NOT NULL,
    user_ip INET,
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    disconnected_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER
);

-- Index for session queries
CREATE INDEX idx_sessions_worker_id ON sessions(worker_id);
CREATE INDEX idx_sessions_connected_at ON sessions(connected_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for workers table
CREATE TRIGGER update_workers_updated_at
    BEFORE UPDATE ON workers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- View for active workers with stats
CREATE OR REPLACE VIEW active_workers AS
SELECT
    w.id,
    w.worker_id,
    w.name,
    w.status,
    w.port,
    w.git_repo,
    w.created_at,
    COUNT(DISTINCT s.id) FILTER (WHERE s.disconnected_at IS NULL) as active_sessions,
    COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'pending') as pending_tasks,
    COUNT(DISTINCT t.id) FILTER (WHERE t.status = 'completed') as completed_tasks
FROM workers w
LEFT JOIN sessions s ON s.worker_id = w.id
LEFT JOIN tasks t ON t.worker_id = w.id
WHERE w.deleted_at IS NULL
GROUP BY w.id;

-- Helper function to log events
CREATE OR REPLACE FUNCTION log_event(
    p_event_type VARCHAR(100),
    p_worker_id UUID DEFAULT NULL,
    p_user_ip INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_details JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO audit_log (event_type, worker_id, user_ip, user_agent, details)
    VALUES (p_event_type, p_worker_id, p_user_ip, p_user_agent, p_details)
    RETURNING id INTO v_id;

    RETURN v_id;
END;
$$ LANGUAGE plpgsql;

-- Sample data for testing (commented out)
-- INSERT INTO workers (worker_id, name, status, port) VALUES ('test-001', 'Test Worker 1', 'running', 7681);
-- INSERT INTO workers (worker_id, name, status, port) VALUES ('test-002', 'Test Worker 2', 'running', 7682);
