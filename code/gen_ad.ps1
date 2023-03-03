param( [parameter(Mandatory=$true)] $JSONFile)

function CreateADGroup {
    param( [parameter(Mandatory=$true)] $userObject)

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global

}

function CreateADUser {
    param( [parameter(Mandatory=$true)] $userObject)

    # Pull out the name from the JSON object
    $name = $userObject.name
    $password = $userObject.password

    # Generate a "first initial, last name" structure username
    $firstname, $lastname = $name.Split(" ")
    $userName = ($name[0] + $lastname).ToLower()
    $samAccountName = $userName
    $principalName = $userName

    # Create the AD user object
    New-ADUser -Name "$name" -GiveName $firstname -SurName $lastname
    -SamAccountName $samAccountName -UserPrincipalName $principalName@Global:Domain
    -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force)
    -PassThrou | EnableADAccount

    # Add the user to it's appropriate group
    foreach ( $group in $userObject.groups ){
        try {
            Get-ADComputer -Identity "$group_name"
            Add-ADGroupMember -Identity $group -Members $userName
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Warning "User $name NOT added to group $group_name becouse it doesn't exist"
        } 
    }
}

$json = ( Get-Content $JSONFile | convertFrom-JSON )

$Global:Domain = $json.domain 

foreach ( $group in $json.groups ){
    CreateADGroup $group
}

foreach ( $user in $json.users ){
    CreateADUser $user
}
