using module .\Atlassian.Bitbucket.Authentication.psm1
<#
.Synopsis
   Ziska seznam uzivatelu s pristupem alespon k jednomu repozitari pro zadany workspace.
.DESCRIPTION
   Tato funkce vraci seznam vsech uzivatelu s pristupem alespon k jednomu repozitari v zadanem workspace. Pokud workspace neni zadan, pouzije se vybrany workspace.
.EXAMPLE
   Get-BitbucketUser
   Vrati seznam uzivatelu pro vychozi workspace.
.EXAMPLE
   Get-BitbucketUser -Workspace $Workspace
   Vrati seznam uzivatelu pro zadany workspace.
#>
function Get-BitbucketUser {
   [CmdletBinding()]
   param(
      [Parameter( ValueFromPipelineByPropertyName = $true,
         HelpMessage = 'Name of the workspace in Bitbucket.  Defaults to selected workspace if not provided.')]
      [Alias("Team")]
      [string]$Workspace = (Get-BitbucketSelectedWorkspace)
   )

   Process {
      $endpoint = "workspaces/$Workspace/members"
      return Invoke-BitbucketAPI -Path $endpoint -Paginated
   }
}
<#
.Synopsis
   Ziska seznam uzivatelu prirazenych ke specifikovane skupine (group slug).
.DESCRIPTION
   Tata funkce vraci seznam vsech uzivatelu prirazenych ke specifikovane skupine (group slug). Pokud workspace neni zadan, pouzije se vybrany workspace.
.EXAMPLE
   Get-BitbucketUsersByGroup -GroupSlug $GroupSlug
   Vrati seznam uzivatelu prirazenych ke specifikovane skupine pro vychozi workspace.
.EXAMPLE
   Get-BitbucketUsersByGroup -Workspace $Workspace -GroupSlug $GroupSlug
   Vrati seznam uzivatelu prirazenych ke specifikovane skupine pro zadany workspace.
#>
function Get-BitbucketUsersByGroup {
   [CmdletBinding()]
   [Obsolete('No longer supported by Atlassian')]
   param(
      [Parameter( ValueFromPipelineByPropertyName = $true,
         HelpMessage = 'Name of the workspace in Bitbucket.  Defaults to selected workspace if not provided.')]
      [Alias("Team")]
      [string]$Workspace = (Get-BitbucketSelectedWorkspace),
      [Parameter (HelpMessage = 'The group slug')]
      [string]$GroupSlug
   )

   Process {
      $endpoint = "groups/$Workspace/$GroupSlug/members"
      return Invoke-BitbucketAPI -Path $endpoint -API_Version '1.0'
   }
}
<#
.Synopsis
   Ziska seznam uzivatelskych skupin.
.DESCRIPTION
   Tato funkce vraci seznam vsech uzivatelskych skupin. Pokud workspace neni zadan, pouzije se vybrany workspace.
.EXAMPLE
   Get-BitbucketGroup
   Vrati seznam skupin pro vychozi workspace.
.EXAMPLE
   Get-BitbucketGroup -Workspace $Workspace
   Vrati seznam skupin pro zadany workspace.
#>
function Get-BitbucketGroup {
   [CmdletBinding()]
   [Obsolete('No longer supported by Atlassian')]
   param(
      [Parameter( ValueFromPipelineByPropertyName = $true,
         HelpMessage = 'Name of the workspace in Bitbucket.  Defaults to selected workspace if not provided.')]
      [Alias("Team")]
      [string]$Workspace = (Get-BitbucketSelectedWorkspace)
   )

   Process {
      $endpoint = "groups/$Workspace"
      return Invoke-BitbucketAPI -Path $endpoint -API_Version '1.0'
   }
}
<#
.Synopsis
   Prida uzivatele do skupiny.
.DESCRIPTION
   Tato funkce prida existujiciho uzivatele do existujici skupiny. Pokud workspace neni zadan, pouzije se vybrany workspace.
.EXAMPLE
   Add-BitbucketUserToGroup -GroupSlug $GroupSlug -UserUuid $UserUuid
   Prida uzivatele do skupiny v ramci vychoziho workspace.
.EXAMPLE
   Add-BitbucketUserToGroup -GroupSlug $GroupSlug -UserUuid $UserUuid -Workspace $Workspace
   Prida uzivatele do skupiny v ramci zadaneho workspace.
#>
function Add-BitbucketUserToGroup {
   [CmdletBinding()]
   [Obsolete('No longer supported by Atlassian')]
   param(
      [Parameter( ValueFromPipelineByPropertyName = $true,
         HelpMessage = 'Name of the workspace in Bitbucket.  Defaults to selected workspace if not provided.')]
      [Alias("Team")]
      [string]$Workspace = (Get-BitbucketSelectedWorkspace),
      [Parameter (HelpMessage = 'The group slug')]
      [string]$GroupSlug,
      [Parameter (HelpMessage = 'The user UUID')]
      [string]$UserUuid
   )

   Process {
      $endpoint = "groups/$Workspace/$GroupSlug/members/$UserUuid"
      return Invoke-BitbucketAPI -Path $endpoint -API_Version '1.0' -Method 'Put'
   }
}
