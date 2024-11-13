function ProcessService {
	param (
		[Parameter(Mandatory=$true)]
        [PSCustomObject]$RepoData,
		[PSCustomObject]$ConfigData,
		[string] $branchName
	)
	Write-Host "✨ ProcessService: Running for $($RepoData.Repo) $($branchName)" -ForegroundColor Blue
	if($branchName -ne "All") {
		RunBranchAction -RepoData $RepoData -ConfigData $ConfigData -branchName $branchName
	}
	else {
		Write-Host "✨ Running for all branch" -ForegroundColor Blue
		foreach ($branch in $RepoData.actions.PSObject.Properties.Name)
		{
			RunBranchAction -RepoData $RepoData -ConfigData $ConfigData -branchName $branch
		}
	}
}

function RunBranchAction {
	param (
		[Parameter(Mandatory=$true)]
        [PSCustomObject]$RepoData,
		[PSCustomObject]$ConfigData,
		[string] $branchName
	)
	$allActions = $RepoData.actions.$branchName
	Write-Host "✨ Running action for Repo: $($RepoData.ServiceName) Branch: $($branchName)" -ForegroundColor Blue
	for($i = 0; $i -lt $allActions.Count; $i++) {
		Write-Host "✨ Running action for Repo: $($RepoData.ServiceName) Branch: $($branchName) Action: $($allActions[$i])" -ForegroundColor Yellow
		# gh api --method POST -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28"  /repos/$($ConfigData.config.owner)/$($RepoData.Repo)/actions/workflows/$($allActions[$i])/dispatches -f "ref=$($branchName)"
		
		$workflowEndpoint = "/repos/$($ConfigData.config.owner)/$($RepoData.Repo)/actions/workflows/$($allActions[$i])/dispatches"
		Write-Host "🗒️ Using file: $($workflowEndpoint)" -ForegroundColor Yellow
		gh api $workflowEndpoint `
        --method POST `
        -H "Accept: application/vnd.github+json" `
        -H "X-GitHub-Api-Version: 2022-11-28" `
        -f ref="$branchName"
	}
}

# Define the path to your JSON configuration file
$configFilePath = "config.json"

# Check if the config file exists
if (!(Test-Path -Path $configFilePath)) {
    Write-Host "Config file not found!" -ForegroundColor Red
    exit
}

# Parse the JSON configuration
$configData = Get-Content -Path $configFilePath -Raw | ConvertFrom-Json

# Define available branch options
$branches = @("All", "develop", "qa", "uat", "master")

# Display branch selection menu
Write-Host "Select branches:"
for ($i = 0; $i -lt $branches.Count; $i++) {
    Write-Host "$($i + 1). $($branches[$i])"
}
$branchSelection = Read-Host "Enter the number corresponding to your branch selection"

# Validate branch selection
if ($branchSelection -lt 1 -or $branchSelection -gt $branches.Count) {
    Write-Host "Invalid branch selection." -ForegroundColor Red
    exit
}
$selectedBranch = $branches[$branchSelection - 1]

# Display repository selection menu based on config data
Write-Host "Select repos:"
Write-Host "1. All"
for ($i = 0; $i -lt $configData.repos.Count; $i++) {
    Write-Host "$($i + 2). $($configData.repos[$i].ServiceName)"
}
$repoSelection = Read-Host "Enter the number corresponding to your repository selection"

# Validate repository selection
if ($repoSelection -lt 1 -or $repoSelection -gt ($configData.repos.Count + 1)) {
    Write-Host "Invalid repository selection." -ForegroundColor Red
    exit
}

# Set selected repository
if ($repoSelection -eq 1) {
    $selectedRepos = "All"
} else {
    $selectedRepos = $configData.repos[$repoSelection - 2].ServiceName
}

# Output selected values
Write-Host "Selected Branch: $selectedBranch" -ForegroundColor Yellow
Write-Host "Selected Repository: $selectedRepos" -ForegroundColor Yellow


Write-Host "🏃‍♀️‍➡️ Running actions" -ForegroundColor Yellow
Write-Host "****************************************************************************"

for ($i = 0; $i -lt $configData.repos.Count; $i++) {
	$repoData = $configData.repos[$i];
	if($selectedRepos -ne "All") {
		if(($i + 2) -eq $repoSelection) {
			ProcessService -RepoData $repoData -branchName $selectedBranch -ConfigData $configData
		}
	}
	else {
		ProcessService -RepoData $repoData -branchName $selectedBranch -ConfigData $configData
	}
}

Write-Host "✅ Actions completed! Happy coding!" -ForegroundColor Green