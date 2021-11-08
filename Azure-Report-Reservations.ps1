$Subscriptions = Get-AzSubscription
Import-Module Az.Reservations
$Timestamp = Get-Date -Format "yyyyMMddHHmm"
$Filename = "Azure-Reservation-Report-$Timestamp.csv"
$Reservations = @()
foreach ($Subscription in $Subscriptions) {
    Set-AzContext -Subscription $Subscription.Id | Out-Null
    $ReservationOrders = Get-AzReservationOrderId
    foreach ($ReservationOrder in $ReservationOrders.AppliedReservationOrderId) {
        $ExtractedId = $ReservationOrder.Split("/")[4]
        $Reservation = Get-AzReservation -ReservationOrderId $ExtractedId -ErrorAction SilentlyContinue
        if ($?) {
            foreach ($Scope in $Reservation.AppliedScopes) {
                $RGId = "$($Scope.Split('/')[0])/$($Scope.Split('/')[1])/$($Scope.Split('/')[2])/$($Scope.Split('/')[3])/$($Scope.Split('/')[4])"
                $RG = Get-AzResourceGroup -Id $RGId
                $Obj += $Reservation
                $Obj | Add-Member -MemberType NoteProperty -Name 'ResourceGroupName' -Value $($RG.ResourceGroupName)
                $Obj | Add-Member -MemberType NoteProperty -Name 'Owner' -Value $($RG.Tags.'Owner')
                $Obj | Add-Member -MemberType NoteProperty -Name 'Product-Id' -Value $($RG.Tags.'Product-Id')
                $Obj | Add-Member -MemberType NoteProperty -Name 'ProductName' -Value $($RG.Tags.'ProductName')
                $Obj | Add-Member -MemberType NoteProperty -Name 'ReservationOrderId' -Value $ExtractedId
                $Obj | Add-Member -MemberType NoteProperty -Name 'SubscriptionName' -Value $($Subscription.Name)
                $Obj | Add-Member -MemberType NoteProperty -Name 'SubscriptionId' -Value $($Subscription.Id) 
                $Reservations += $Obj
            }
        } else {
            write-host "Error reservation $ExtractedId in Subscription $($Subscription.Name) unaccessible"
        }
    }
}

$Reservations | Select-Object ResourceGroupName,Owner,Product-Id,ProductName,Sku,Location,ReservedResourceType,ExpiryDate,SubscriptionName,SubscriptionId,ReservationOrderId | convertto-csv | Out-File -FilePath .\$Filename 