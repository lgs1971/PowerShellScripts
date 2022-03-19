# Get the credentials to be used when setting the values
# https://technet.microsoft.com/en-us/library/dn975125.aspx
$UserCredential = Get-Credential

# Connect to Office 365 using the credentials
Connect-MsolService -Credential $UserCredential

# Since it is quite possible for someone to misspell a parameter, it is best if we check that all parameters in the .CSV file are valid
# We start by making a list of which parameters are valid for the command we are going to run:

# https://msdn.microsoft.com/en-us/library/azure/dn194136%28v=azure.98%29.aspx
$Params = Get-Command Set-MsolUser
$ValidParams = $Params.ParameterSets[0] | Select -ExpandProperty Parameters | select -ExpandProperty Name
#$ValidParams = @("AlternateEmailAddresses", "BlockCredential", "City", "Country", "Department", "DisplayName", "Fax", "FirstName", "ImmutableId", "LastName", "MobilePhone", "ObjectId", "Office", "PasswordNeverExpires", "PhoneNumber", "PostalCode", "PreferredLanguage", "State", "StreetAddress", "StrongPasswordRequired", "TenantId", "Title", "UsageLocation", "UserPrincipalName")

# This is the path to and name of the .CSV-file we are using as input
# https://technet.microsoft.com/en-us/library/hh849891.aspx
#$CSVFile = Import-Csv "C:\Users\rsm\Documents\Kunder\Move\Operations\AD Vedal users.csv" -Delimiter ";" -Encoding UTF8
$CSVFile = Import-Csv "C:\Users\rsm\Documents\Kunder\Move\Operations\users_11-27-2016 9-33-26 AM.csv" -Delimiter ";" -Encoding UTF8

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
# Print the parameter string, just in case there is an error
  Set-MsolUser @Params
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
# ...we can trust PowerShell to write a nice table for us on screen
# https://social.technet.microsoft.com/Forums/scriptcenter/en-US/dcd86e30-9ae3-4479-b92a-64c86e91df50/powershell-20-selectobject-using-variable-contents-read-from-text-file?forum=ITCG
  Get-MSolUser | Select -Property ([string[]]$Params)
} else
{
# ...else we ask PowerShell to write a list
  Get-MSolUser | Select -Property ([string[]]$Params) | Format-List -Property *
}