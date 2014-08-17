package provide interchange 1.0
package require sqlite3
package require gen

namespace eval InventoryNS {

proc Create {Desc} {
     set sql "INSERT INTO inventories (desc) VALUES ('$Desc')"
     puts $sql
     mydb eval $sql
     return [LastId inventories]
}

proc Delete {InventoryIds} {
     set sql "DELETE FROM inventory_info WHERE inventoryid IN ([join $InventoryIds ","])"
     mydb eval $sql
     set sql "DELETE FROM inventories WHERE id IN ([join $InventoryIds ","])"
     puts $sql
     mydb eval $sql
}

proc ChangeDesc {InventoryId NewDesc} {
     set sql "UPDATE inventories SET desc = '$NewDesc' WHERE id = $InventoryId"
     puts $sql
     mydb eval $sql
}

proc AddItem {InventoryId MenuId {Amount 0}} {
     set sql "INSERT INTO inventory_info (inventoryid, menuid, amount) VALUES ($InventoryId, $MenuId, $Amount)"
     puts $sql
     mydb eval $sql
}

proc RemoveItem {InventoryId MenuId} {
     set sql "DELETE FROM inventory_info WHERE inventoryid = $InventoryId AND menuid = $MenuId"
     puts $sql
     mydb eval $sql
}

proc StockLevel {InventoryId MenuId} {
     set sql "SELECT amount FROM inventory_info WHERE inventoryid = $InventoryId AND menuid = $MenuId"
     puts $sql
     mydb eval $sql
}

proc IncreaseStock {InventoryId MenuId Amount} {
     set CurrentLevel [StockLevel $InventoryId $MenuId]
     set NewLevel [expr $CurrentLevel + $Amount]
     AdjustLevel $InventoryId $MenuId $NewLevel
}

proc ReduceStock {InventoryId MenuId Amount} {
     set CurrentLevel [StockLevel $InventoryId $MenuId]
     set NewLevel [expr $CurrentLevel - $Amount]
     puts "ReduceStock: $InventoryId $MenuId $Amount"
     puts "CurrentLevel = $CurrentLevel, NewLevel = $NewLevel"
     AdjustLevel $InventoryId $MenuId $NewLevel
}

proc AdjustLevel {InventoryId MenuId Amount} {
     set sql "UPDATE inventory_info SET amount = $Amount WHERE inventoryid = $InventoryId AND menuid = $MenuId"
     puts $sql
     mydb eval $sql
}

proc ListInventories {} {
     set sql "SELECT id, desc FROM inventories"
     puts $sql
     return [RunSelect $sql]
}

proc ListItems {InventoryIds} {
     set sql "SELECT x.id, x.inventoryid, y.desc, x.amount FROM inventory_info x JOIN menu_items y ON x.menuid = y.id WHERE inventoryid IN ([join $InventoryIds ","])"
     puts $sql
     return [RunSelect $sql]
}

proc LogAdjustment {InventoryId MenuId Type {Amount 1} {When 0}} {
     if {$When == 0} {
          set When "datetime('now', 'localtime')"
     } else {
          set When "'$When'"
     }
     
     set sql "INSERT INTO inventory_logs (inventoryid, menuid, type, amount, cuando) VALUES ($InventoryId, $MenuId, '$Type', $Amount, $When)"
     puts $sql
     mydb eval $sql
     return [LastId inventory_logs]
}


}
