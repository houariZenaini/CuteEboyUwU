


if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "Le module Active Directory n'est pas installé. Installation en cours..."
    Install-WindowsFeature -Name "RSAT-AD-PowerShell"
    Import-Module ActiveDirectory
}
# Chemin du pti csv tout cute avec tout les esclave a l'interieur du fichier CSV
$csvPath = ".\users.csv"

if (-not (Test-Path $csvPath)) {
    Write-Host "Erreur : Le fichier CSV $csvPath n'existe pas." -ForegroundColor Red
    exit 1
}


$users = Import-Csv $csvPath
foreach ($user in $users) {
    $username = $user.SamAccountName
    $fullname = $user.Name
    $password = ConvertTo-SecureString $user.Password -AsPlainText -Force
    $ou = $user.OU

   
    if (Get-ADUser -Filter {SamAccountName -eq $username}) {
        Write-Host "Utilisateur $username existe déjà. Ignoré." -ForegroundColor Yellow
    } else {
        # Création de mes esclave 
        New-ADUser -SamAccountName $username `
                   -UserPrincipalName "$username@domaine.local" `
                   -Name $fullname `
                   -GivenName $user.FirstName `
                   -Surname $user.LastName `
                   -Path $ou `
                   -AccountPassword $password `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true `
                   -PassThru

        Write-Host "Utilisateur $username créé avec succès." -ForegroundColor Green
    }
}
