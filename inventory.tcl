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

proc Replicate {InventoryId {NewInventoryDesc 0}} {
     if {$NewInventoryDesc == 0} {
          set NewInventoryDesc "Replica of -- [Q1 "SELECT desc FROM inventories WHERE id = $InventoryId"]"          
     }
     
     set NewInventoryId [Create $NewInventoryDesc]
     set sql "SELECT menuid, amount FROM inventory_info WHERE inventoryid = $InventoryId"
     set Results [Raise [mydb eval $sql] 2]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set Amount [lindex $Result 1]
          
          AddItem $NewInventoryId $MenuId $Amount
     }
     
     return $NewInventoryId
}

proc ReplicateAsOf {InventoryId DateTime {NewInventoryDesc 0}} {
     if {$NewInventoryDesc == 0} {
          set NewInventoryDesc "Replica of -- [Q1 "SELECT desc FROM inventories WHERE id = $InventoryId"] -- at $DateTime"          
     }
     
     set NewInventoryId [Replicate $InventoryId $NewInventoryDesc]
     set sql "SELECT menuid, type, amount FROM inventory_logs WHERE cuando >= '$DateTime' ORDER BY cuando DESC"
     set Results [Raise [mydb eval $sql] 3]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set Type [lindex $Result 1]
          set Amount [lindex $Result 2]
          puts "Got MenuId = $MenuId, Type = $Type, Amount = $Amount"
          switch $Type {
               increase {
                    ReduceStock $NewInventoryId $MenuId $Amount
               }
               reduce {
                    IncreaseStock $NewInventoryId $MenuId $Amount
               }
          }
     }
     
     return $NewInventoryId
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

proc Compare {LeftInventoryId RightInventoryId} {
     set ProtoTransactionList {}
     
     # Return a list of tuples that could be used to 
     # make a series of transactions to make the left 
     # equal to the right.
     
     # Items where left is greater than right
     set sql "SELECT i1.menuid, i1.amount, i2.amount FROM inventory_info i1, inventory_info i2 ON i1.menuid = i2.menuid WHERE i1.inventoryid = $LeftInventoryId AND i2.inventoryid = $RightInventoryId AND i1.amount > i2.amount"
     puts $sql
     set Results [Raise [mydb eval $sql] 3]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set LeftAmount [lindex $Result 1]
          set RightAmount [lindex $Result 2]
          set Difference [expr $LeftAmount - $RightAmount]
          
          lappend ProtoTransactionList [list $MenuId "reduce" $Difference]
     }
     # Items where right is greater than left
     set sql "SELECT i1.menuid, i1.amount, i2.amount FROM inventory_info i1, inventory_info i2 ON i1.menuid = i2.menuid WHERE i1.inventoryid = $LeftInventoryId AND i2.inventoryid = $RightInventoryId AND i1.amount < i2.amount"
     puts $sql
     set Results [Raise [mydb eval $sql] 3]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set LeftAmount [lindex $Result 1]
          set RightAmount [lindex $Result 2]
          set Difference [expr $RightAmount - $LeftAmount]
          
          lappend ProtoTransactionList [list $MenuId "increase" $Difference]
     }
     # Items on left but not on right
     set sql "SELECT i1.menuid, i1.amount FROM inventory_info i1 WHERE i1.inventoryid = $RightInventoryId AND (SELECT count(*) FROM inventory_info i2 WHERE menuid = i1.menuid) = 0"
     puts $sql
     set Results [Raise [mydb eval $sql] 2]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set Amount [lindex $Result 1]
          
          lappend ProtoTransactionList [list $MenuId "reduce" $Difference]
     }
     # Items on right but not on left
     set sql "SELECT i2.menuid, i2.amount FROM inventory_info i2 WHERE i2.inventoryid = $RightInventoryId AND (SELECT count(*) FROM inventory_info i1 WHERE menuid = i2.menuid) = 0"
     puts $sql     
     set Results [Raise [mydb eval $sql] 2]
     foreach Result $Results {
          set MenuId [lindex $Result 0]
          set Amount [lindex $Result 1]
          
          lappend ProtoTransactionList [list $MenuId "increase" $Difference]
     }
     
     return $ProtoTransactionList
}

}
