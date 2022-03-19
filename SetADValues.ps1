# Get the credentials to be used when setting the values
$UserCredential = Get-Credential

# Since it is quite possible for someone to misspell a parameter, it is best if we check that all parameters in the .CSV file are valid
# We start by making a list of which parameters are valid for the command we are going to run:
# https://technet.microsoft.com/en-us/library/hh852287%28v=wps.630%29.aspx
$Params = Get-Command Set-ADUser
$ValidParams = $Params.ParameterSets[0] | Select -ExpandProperty Parameters | select -ExpandProperty Name
#$ValidParams = @("Principal", "AccountExpirationDate", "AccountNotDelegated", "AllowReversiblePasswordEncryption", "AuthenticationPolicy", "AuthenticationPolicySilo", "AuthType", "CannotChangePassword", "Certificates", "ChangePasswordAtLogon", "City", "Company", "CompoundIdentitySupported", "Country", "Department", "Description", "DisplayName", "Division", "EmailAddress", "EmployeeID", "EmployeeNumber", "Enabled", "Fax", "GivenName", "HomeDirectory", "HomeDrive", "HomePage", "HomePhone", "Initials", "KerberosEncryptionType", "LogonWorkstations", "Manager", "MobilePhone", "Office", "OfficePhone", "Organization", "OtherName", "Partition", "PasswordNeverExpires", "PasswordNotRequired", "POBox", "PostalCode", "PrincipalsAllowedToDelegateToAccount", "ProfilePath", "SamAccountName", "ScriptPath", "Server", "SmartcardLogonRequired", "State", "StreetAddress", "Surname", "Title", "TrustedForDelegation", "UserPrincipalName")

# This is the path to and name of the .CSV-file we are using as input
# https://technet.microsoft.com/en-us/library/hh849891.aspx
#$CSVFile = Import-Csv "C:\Users\rsm\Documents\Kunder\Move\Operations\AD Vedal users.csv" -Delimiter ";" -Encoding UTF8
$CSVFile = Import-Csv "C:\Users\rsm\Documents\Kunder\Move\Operations\Arne.csv" -Delimiter ";" -Encoding UTF8

# Get the column names from the .CSV files
$ColumnNames = $CSVFile | Get-Member -MemberType NoteProperty | foreach {$_.Name}
#Write-Host $ColumnNames

# For each of the lines in the .CSV-file...
foreach($Item in $CSVFile)
{
# Create an empty array to store the parameter names
  $Params = @{}
# Clear the temporary string
  $TempStr = ""
# For each of the column names...
  foreach ($ColName in $ColumnNames)
  {
#   ...check if the column name is a valid parameter
    if ($ValidParams -contains $ColName)
    {
#     If it is, add the column name and the value from the currently processed user object to the parameter array as a hash value
      $Params.Add($ColName, $Item.$ColName)
    }
#   If the temporary string is empty...
    if ($TempStr)
    {
#     ...then set the temporary string to the column name plus = plus the column value
      $TempStr = ($ColName + "=" + $Item.$ColName)
    } else
    {
#     ...else set the temporary string to the temporary string plus the column name plus = plus the column value
      $TempStr = ($TempStr + ";" + $ColName + "=" + $Item.$ColName)
    }
  }
#  Write-Host @Params
#  Write-Output $TempStr
# Set the values from the parameter array
# http://stackoverflow.com/questions/5956862/how-to-use-a-powershell-variable-as-command-parameter
  Set-ADUser -Credential $UserCredential @Params
}

# Create an empty collection to use when storing the parameters we want to check
$Params = [System.Collections.ArrayList]@()
# For each of the column names...
foreach($ColName in $ColumnNames)
{
# ...check if the column name is a valid parameter
  if ($ValidParams -contains $ColName)
  {
#   If it is, add the column name to the parameter array (it really is a collection as we cannot add to an array)
    $Params.Add($ColName)
  }
}
#Write-Host $Params

# If the number of parameters is lower than 4...
if ($Params.Count -lt 4)
{
# https://social.technet.microsoft.com/Forums/scriptcenter/en-US/dcd86e30-9ae3-4479-b92a-64c86e91df50/powershell-20-selectobject-using-variable-contents-read-from-text-file?forum=ITCG
# ...we can trust PowerShell to write a nice table for us on screen
  Get-ADUser | Select -Property ([string[]]$Params)
} else
{
# ...else we ask PowerShell to write a list
  Get-ADUser | Select -Property ([string[]]$Params) | Format-List -Property *
}