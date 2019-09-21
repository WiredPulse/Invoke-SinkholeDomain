function Sink-Domain($domain){
    Add-DnsServerPrimaryZone -Name "0-Sinkhole_Domains" -ZoneFile "0-Sinkhole_Domains"
    Add-DnsServerPrimaryZone -Name "$domain" -ZoneFile "0-Sinkhole_Domains"

    Add-DnsServerResourceRecordA -ZoneName $domain -Name $domain -IPv4Address 0.0.0.0
    Add-DnsServerResourceRecordA -ZoneName $domain -Name * -IPv4Address 0.0.0.0
    Sync-DnsServerZone
}

function Mass-Sink{
    $url = "http://malware-domains.com/files/domains.zip"
    $currentUser = $env:USERPROFILE
    $output = "$env:USERPROFILE\desktop\domains.zip"
    Invoke-WebRequest -Uri $url -OutFile $output

    $shell = new-object -com shell.application
    $zip = $shell.NameSpace("$env:USERPROFILE\Desktop\domains.zip”)
    foreach($item in $zip.items())
        {
        $shell.Namespace(“$env:USERPROFILE\desktop”).copyhere($item)
        }

    $spaces = Get-Content "$env:USERPROFILE\desktop\domains.txt" | select -skip 4 | Foreach {($_ -split '\s+',4)[0..1]}
    $sites = $spaces | where-object{$_ -ne ""}

    Add-DnsServerPrimaryZone -Name "0-Sinkhole_Domains" -ZoneFile "0-Sinkhole_Domains"
    foreach($item in $sites){
        Add-DnsServerPrimaryZone -Name "$item" -ZoneFile "0-Sinkhole_Domains"
        Add-DnsServerResourceRecordA -ZoneName "$item" -Name $item -IPv4Address 0.0.0.0
        Add-DnsServerResourceRecordA -ZoneName "$item" -Name * -IPv4Address 0.0.0.0
    }
    Remove-Item $env:USERPROFILE\desktop\domains.txt
    Remove-Item $env:USERPROFILE\desktop\domains.zip
}

function Sink-Removal{
    $zone = (Get-DnsServerZone |?{$_.zonefile -eq "0-Sinkhole_Domains"}).zonename

    foreach($item in $zone){
        Remove-DnsServerZone -Name $item -Force
    }
}

function Sinkhole-Hosts{
param([string[]]$domains)
    #Requires -RunAsAdministrator
    $file = "C:\Windows\System32\drivers\etc\hosts"
    $domains
    foreach($item in $domains){
        "0.0.0.0       $item" | out-file $file -append
    } 
}

function Restore-Hosts{
    $file = "C:\Windows\System32\drivers\etc\hosts"
    $hosts = get-content $file
    remove-item $file
    foreach($item in $hosts){
        if($item -like "`#*"){
            $item | out-file C:\Windows\System32\drivers\etc\hosts -Append      
        }
    }
}
