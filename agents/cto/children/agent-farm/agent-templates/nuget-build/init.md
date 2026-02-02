# Task: Build NuGet Repository

Build the NuGet repository and report the number of build warnings encountered.

## Location
Clone into your private home directory:
```bash
mkdir -p ~/repos && cd ~/repos
git clone git@bitbucket.org:xynon/nq-nugetlibraries.git nuget
```
Solution: `NQ.AllNuget.sln`

## Steps
1. Clone and navigate to the nuget repository
2. Run `dotnet build NQ.AllNuget.sln`
3. Count the number of warnings in the output
4. Report the warning count back to parent

## Deliverable
Update your `report.md` with:
- Build success/failure status
- Total warning count
- Summary of warning types (if any)

Then message parent via inbox with the results.
