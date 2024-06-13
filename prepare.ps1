# Define the list of packages
$packages = @("jqlang.jq", "GitHub.cli", "Git.Git", "Git.Bash")

# Loop through the list and install each package
foreach ($package in $packages) {
    Write-Host "Installing $package"
    Start-Process -NoNewWindow -FilePath "winget" -ArgumentList "install $package"
}
