# SetFormBuilderURL - written by Ragnar Storstrøm, 2022
# This script does the following:
# - It finds your NetIQ Designer installation
# - It asks for the Form Renderer URL
# - It finds all configuration files that should contain this URL and sets the value to the URL you supplied

Add-Type -AssemblyName Microsoft.VisualBasic

# We don't know what the installation directory is yet...
$InstallDir = $null

# The filename we are looking for
$Filename = "designer.exe"
# The path separator to use when building paths
$PathSeparator = "\"

# The name of the plugin directory
$PluginDir = "plugins"

$FormBuilderPluginPattern = "com.mf.win.win32.formbuilder_*"

# The default path for Designer in registry
$DefRegPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Designer for Identity Manager"

# If the registry path exists...
if (Test-Path $DefRegPath)
{
# ...then let the user know that Designer appears to be installed
  Write-Host "Designer looks to be installed based on information in registry, checking..."

# Get the registry value which contains the installation directory
  $InstallDir = Get-ItemProperty -Path $DefRegPath -Name InstallLocation | Select-Object -ExpandProperty InstallLocation

# Prepare to check if the .EXE file exists in the directory specified in registry
  $ExeLocation = ($InstallDir + $PathSeparator + $Filename)
# If the .EXE file is found...
  if (Test-Path -Path $ExeLocation -PathType Leaf)
  {
#   ...then print a message to the user that Designer has been found
    Write-Host "The Designer install location was found based on information in registry"
  } else
  {
#   ...else print a message to the user that we need to look further
    Write-Host "Designer was NOT found in the location specified in registry..."
#   Clear the installation directory to allow for a search of the file system
    $InstallDir = $null
  }
}

# If the installation directory was not found in the registry...
if ($InstallDir -eq $null)
{
# ...then let the user know that we have to look in the file system
  Write-Host "Designer was NOT found in registry, starting a search on disk..."
# Set the default installation location for Designer
  $InstallDir = "C:\netiq\idm\apps\Designer"

# Prepare to check if the .EXE file exists in the default installation directory
  $ExeLocation = ($InstallDir + $PathSeparator + $Filename)

# If the .EXE file is found...
  if (Test-Path -Path $ExeLocation -PathType Leaf)
  {
#   ...then print a message to the user that Designer has been found
    Write-Host "Designer was found in the default location!"
  } else
  {
#   ...else print a message to the user that we need to look further
    Write-Host "Designer is NOT in the default location, starting a search..."

#   Get all available drives
    $Drives = (Get-PSDrive).Name -match '^[a-z]$'

#   For each available drive...
    ForEach ($Drive in $Drives)
    {
#     ...then if the installation directory has not been found...
      if ($InstallDir -eq $null)
      {
#       ...search for designer.exe in the filesystem
        $Paths = Get-ChildItem -Path $Drive -Include $Filename -File -Recurse -ErrorAction SilentlyContinue

#       For each path where designer.exe was found...
        ForEach ($Path in $Paths)
        {
#         ...then if the installation directory has not been found...
          if ($InstallDir -eq $null)
          {
#           ...set the default installation location for Designer
            $InstallDir = $Path.DirectoryName

#           Prepare to check if the .EXE file exists in the default installation directory
            $ExeLocation = ($InstallDir + $PathSeparator + $Filename)

#           If the .EXE file is found...
            if (Test-Path -Path $ExeLocation -PathType Leaf)
            {
#             ...then print a message to the user that Designer has been found
              Write-Host "The Designer install location was found based on a search on available drives"
            } else
            {
#             ...else clear the installation directory to continue the search
              $InstallDir = $null
            }
          }
        }
      }
    }
  }
}

# If the installation directory was found...
if ($InstallDir -ne $null)
{
# ...then prepare the message box by setting the title and message to display
  $Title = 'Form Builder URL changer'
  $Msg   = 'Enter the path to the Form Builder instance you wish to use:'

# Display the input box with the title and message
  $FormBuilderURL = [Microsoft.VisualBasic.Interaction]::InputBox($Msg, $Title)

# Prepare to look for Form Builder plugins
  $PluginPath = ($InstallDir + $PathSeparator + $PluginDir)
  $FormBuilderPath = ($PluginPath + $PathSeparator + $FormBuilderPluginPattern)

# Look for a file names ServiceRegistry.json in the Form Builder plugin paths
  $Paths = Get-ChildItem -Path $FormBuilderPath -Include "serviceregistry.json" -Recurse -ErrorAction SilentlyContinue

# For each path found...
  ForEach ($Path in $Paths)
  {
#   ...print a message to the user with the name of the path
    Write-Host ("Checking the JSON data in file with path " + $Path.FullName + "...")
#   Get the file data in JSON format
    $JSONData = Get-Content -Path $Path.FullName | ConvertFrom-Json
#   Comment out the line above and uncomment the one below in order to reset the file data in case the file is corrupted
#    $JSONData = '{"FormsBackendUrl":"https://192.168.46.30:8600/WFHandler"}' | ConvertFrom-Json

#   If the current FormsBackendUtl value does not match the user's selected value...
    if ($JSONData.FormsBackendUrl -ne $FormBuilderURL)
    {
#     ...then change the URL to the user's selected value
      $JSONData.FormsBackendUrl = $FormBuilderURL
#     Convert the object back to JSON data and write it to file
      $JSONData | ConvertTo-Json -depth 100 | Out-File $Path.FullName
#     Print a message to the user that the file has been updated
      Write-Host ("Setting the JSON data in file with path " + $Path.FullName + "...")
    }

#   Print a message to the user that the file has been processed
    Write-Host ("Done setting the JSON data in file with path " + $Path.FullName + "!")
  }
}
