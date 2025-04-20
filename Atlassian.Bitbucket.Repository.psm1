using module .\Atlassian.Bitbucket.Authentication.psm1

<#
    .SYNOPSIS
        Vrati vsechny repozitare ve workspace.

    .DESCRIPTION
        Vrati vsechny Bitbucket repozitare ve workspace nebo vsechny repozitare ve specifikovanem projektu.

    .EXAMPLE
        C:\PS> Get-BitbucketRepository
        Vrati vsechny repozitare pro aktualne vybrany workspace.

    .EXAMPLE
        C:\PS> Get-BitbucketRepository -ProjectKey 'KEY'
        Vrati vsechny repozitare pro specifikovany projekt.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER ProjectKey
        Klic projektu v Bitbucket.
#>
function Get-BitbucketRepository {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter( Position = 1,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Klic projektu v Bitbucket.')]
        [string]$ProjectKey
    )

    Process {
        $endpoint = "repositories/$Workspace"

        if ($RepoSlug) {
            return Invoke-BitbucketAPI -Path "$endpoint/$RepoSlug"
        }
        elseif ($ProjectKey) {
            # Filter to a specific project
            $endpoint += "?q=project.key=%22$ProjectKey%22"
        }
        return Invoke-BitbucketAPI -Path $endpoint -Paginated
    }
}

<#
    .SYNOPSIS
        Vytvori novy repozitar ve workspace.

    .DESCRIPTION
        Vytvori novy Bitbucket repozitar ve workspace a ve specifikovanem projektu, pokud je zadan.

    .EXAMPLE
        C:\PS> New-BitbucketRepository -RepoSlug 'NewRepo'
        Vytvori novy repozitar v Bitbucket s nazvem NewRepo. Pokud projekt neni zadan, repozitar je automaticky prirazen k nejstarsimu projektu ve workspace.

    .EXAMPLE
        C:\PS> New-BitbucketRepository -RepoSlug 'NewRepo' -ProjectKey 'KEY'
        Vytvori novy repozitar v Bitbucket s nazvem NewRepo a priradi ho do projektu KEY.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER Name
        Nastavi pratelstejsi nazev pro repozitar.

    .PARAMETER ProjectKey
        Klic projektu v Bitbucket.

    .PARAMETER Private
        Zda by mel byt repozitar privatni nebo verejny. Vychozi hodnota je privatni.

    .PARAMETER Description
        Popis repozitare.

    .PARAMETER Language
        Programovaci jazyk pouzity v repozitari.

    .PARAMETER ForkPolicy
        Politika forku repozitare. [allow_forks, no_public_forks, no_forks]
#>
function New-BitbucketRepository {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nastavi pratelstejsi nazev pro repozitar.')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Klic projektu v Bitbucket.')]
        [string]$ProjectKey,
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Zda by mel byt repozitar privatni nebo verejny.')]
        [boolean]$Private = $true,
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Popis repozitare.')]
        [string]$Description = '',
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Programovaci jazyk pouzity v repozitari.')]
        [ValidateSet('java', 'javascript', 'python', 'ruby', 'php', 'powershell')]
        [string]$Language = '',
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Politika forku repozitare. [allow_forks, no_public_forks, no_forks]')]
        [ValidateSet('allow_forks', 'no_public_forks', 'no_forks')]
        [string]$ForkPolicy = 'no_forks'
    )

    Process {
        $endpoint = "repositories/$Workspace/$RepoSlug"

        if ($ProjectKey) {
            $body = [ordered]@{
                scm         = 'git'
                project     = [ordered]@{
                    key = $ProjectKey
                }
                is_private  = $Private
                name        = if ($Name) { $Name } else { $RepoSlug }
                description = $Description
                language    = $Language
                fork_policy = $ForkPolicy
            } | ConvertTo-Json -Depth 2 -Compress
        }
        else {
            $body = [ordered]@{
                scm         = 'git'
                is_private  = $Private
                name        = if ($Name) { $Name } else { $RepoSlug }
                description = $Description
                language    = $Language
                fork_policy = $ForkPolicy
            } | ConvertTo-Json -Depth 2 -Compress
        }

        if ($pscmdlet.ShouldProcess($RepoSlug, 'create')) {
            return Invoke-BitbucketAPI -Path $endpoint -Body $body  -Method Post
        }
    }
}

<#
    .SYNOPSIS
        Aktualizuje existujici repozitar.

    .DESCRIPTION
        Aktualizuje vlastnosti existujiciho repozitare v Bitbucket. Muzete nastavit jednu nebo vice vlastnosti najednou.

    .EXAMPLE
        C:\PS> Set-BitbucketRepository -RepoSlug 'Repo' -Language 'Java'
        Nastavi jazyk repozitare na Java.

    .EXAMPLE
        C:\PS> Set-BitbucketRepository -RepoSlug 'Repo' -ProjectKey 'KEY'
        Presune repozitar do projektu 'KEY'.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER Name
        Prejmenuje repozitar v Bitbucket. Take prejmenuje Slug.

    .PARAMETER ProjectKey
        Klic projektu v Bitbucket.

    .PARAMETER Private
        Zda by mel byt repozitar privatni nebo verejny.

    .PARAMETER Description
        Popis repozitare.

    .PARAMETER Language
        Programovaci jazyk pouzity v repozitari.

    .PARAMETER ForkPolicy
        Politika forku repozitare. [allow_forks, no_public_forks, no_forks]
#>
function Set-BitbucketRepository {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter( HelpMessage = 'Nastavi pratelstejsi nazev pro repozitar.')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [Parameter( HelpMessage = 'Klic projektu v Bitbucket.')]
        [string]$ProjectKey,
        [Parameter( HelpMessage = 'Zda by mel byt repozitar privatni nebo verejny.')]
        [boolean]$Private,
        [Parameter( HelpMessage = 'Popis repozitare.')]
        [string]$Description,
        [Parameter( HelpMessage = 'Programovaci jazyk pouzity v repozitari.')]
        [ValidateSet('java', 'javascript', 'python', 'ruby', 'php', 'powershell')]
        [string]$Language,
        [Parameter( HelpMessage = 'Politika forku repozitare. [allow_forks, no_public_forks, no_forks]')]
        [ValidateSet('allow_forks', 'no_public_forks', 'no_forks')]
        [string]$ForkPolicy
    )

    Process {
        $endpoint = "repositories/$Workspace/$RepoSlug"
        $body = [ordered]@{}

        if ($ProjectKey) {
            $body += [ordered]@{
                project = [ordered]@{
                    key = $ProjectKey
                }
            }
        }
        if ($Private) {
            $body += [ordered]@{
                is_private = $Private
            }
        }
        if ($Name) {
            $body += [ordered]@{
                name = $Name
            }
        }
        if ($Description) {
            $body += [ordered]@{
                description = $Description
            }
        }
        if ($Language) {
            $body += [ordered]@{
                language = $Language
            }
        }
        if ($ForkPolicy) {
            $body += [ordered]@{
                fork_policy = $ForkPolicy
            }
        }
        if ($body.Count -eq 0) {
            throw "No settings provided to update"
        }

        $body = $body | ConvertTo-Json -Depth 2 -Compress

        if ($pscmdlet.ShouldProcess($RepoSlug, 'update')) {
            return Invoke-BitbucketAPI -Path $endpoint -Body $body -Method Put
        }
    }
}

<#
    .SYNOPSIS
        Smaze specifikovany repozitar.

    .DESCRIPTION
        Smaze specifikovany repozitar. Toto je nevratna operace. Toto neovlivni jeho forky.

    .EXAMPLE
        C:\PS> Remove-BitbucketRepository -RepoSlug 'Repo1'
        Smaze repozitar s nazvem Repo1.

    .EXAMPLE
        C:\PS> Remove-BitbucketRepository -RepoSlug 'Repo1' -Redirect 'NewURL'
        Smaze repozitar s nazvem Repo1 a zanecha zpravu o presmerovani pro budouci navstevniky.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER Redirect
        Pokud byl repozitar presunut na nove umisteni, pouzijte tento parametr k zobrazeni zpravy v Bitbucket UI, ze repozitar byl presunut na nove umisteni. Nicmene GET na tento endpoint stale vrati 404.
#>
function Remove-BitbucketRepository {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Presmerovaci retezec.')]
        [string]$Redirect
    )

    Process {
        $endpoint = "repositories/$Workspace/$RepoSlug"

        if ($Redirect) {
            $endpoint += "?redirect_to=$Redirect"
        }

        if ($pscmdlet.ShouldProcess($RepoSlug, 'permanently delete')) {
            return Invoke-BitbucketAPI -Path $endpoint -Method Delete
        }
    }
}

<#
    .SYNOPSIS
        Vytvori novou vetev.

    .DESCRIPTION
        Vytvori vetev ve specifikovanem repozitari. Pokud neni specifikovan rodic, vetev bude vytvorena z posledniho commitu vychozi vetve.

    .EXAMPLE
        C:\PS> Add-BitBucketRepositoryBranch -Branch 'NewBranch' -Workspace 'MyWorkspace' -RepoSlug 'Repo1'
        Prida novou vetev z posledniho commitu vychozi vetve.

    .EXAMPLE
        C:\PS> Add-BitBucketRepositoryBranch -Branch 'NewBranch' -Parent 'CommitHash'
        Prida novou vetev ze specifikovaneho commitu.

    .EXAMPLE
        C:\PS> Add-BitBucketRepositoryBranch -Branch 'NewBranch' -Message 'Create new branch'
        Prida novou vetev se specifikovanou commitovou zpravou.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER Branch
        Nazev vetve, kterou chcete vytvorit.

    .PARAMETER Parent
        Volitelny hash commitu, ze ktereho chcete vetev vytvorit.

    .PARAMETER Message
        Volitelna commitova zprava pro novou vetev.
#>
function Add-BitbucketRepositoryBranch {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter( Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev vetve, kterou chcete vytvorit.')]
        [string]$Branch,
        [Parameter(HelpMessage = 'Hash commitu, ze ktereho chcete vetev vytvorit.')]
        [string]$Parent,
        [Parameter(HelpMessage = 'Commitova zprava pro novou vetev.')]
        [string]$Message
    )

    Process {
        $endpoint = "repositories/$Workspace/$RepoSlug/src/"

        $body = [ordered]@{branch = $Branch }

        if ($Parent) {
            $body.Add("parents", $parent)
        }

        if ($Message) {
            $body.Add("message", $message)
        }

        return Invoke-BitbucketAPI -Path $endpoint -Body $body -Method Post -ContentType 'application/x-www-form-urlencoded'
    }
}

<#
    .SYNOPSIS
        Vrati vetve ve specifikovanem repozitari.

    .DESCRIPTION
        Vrati vetve ve specifikovanem repozitari.

    .EXAMPLE
        C:\ PS> Get-BitbucketRepositoryBranch -RepoSlug 'repo'
        Vrati vsechny vetve v repozitari s nazvem repo.

    .EXAMPLE
        C:\ PS> Get-BitbucketRepositoryBranch -RepoSlug 'repo' -Name 'feature'
        Vrati vsechny vetve v repozitari s nazvem repo, ktere obsahuji slovo feature ve svem nazvu.

    .PARAMETER Workspace
        Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.

    .PARAMETER RepoSlug
        Nazev repozitare v Bitbucket.

    .PARAMETER Name
        Nazev vetve, kterou chcete vyhledat.
#>
function Get-BitbucketRepositoryBranch {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev workspace v Bitbucket. Pokud neni zadan, pouzije se vybrany workspace.')]
        [Alias("Team")]
        [string]$Workspace = (Get-BitbucketSelectedWorkspace),
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Nazev repozitare v Bitbucket.')]
        [Alias('Slug')]
        [string]$RepoSlug,
        [Parameter(HelpMessage = 'Vyhledat specifikovany nazev vetve.')]
        [string]$Name
    )

    Process {
        $endpoint = "repositories/$Workspace/$RepoSlug/refs/branches?q=name~`"$Name`""

        return Invoke-BitbucketAPI -Path $endpoint -Paginated
    }
}