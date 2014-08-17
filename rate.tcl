package provide interchange 1.0
package require sqlite3
package require gen

namespace eval RateNS {

proc Create {Desc} {
     set sql "INSERT INTO rates (desc) VALUES ('$Desc')"
     DbgPrint $sql
     mydb eval $sql
     return [LastId rates]
}

proc Delete {RateIds} {
     set RateIdsCoseList [join $RateIds ","]
     set sql "DELETE FROM rate_items WHERE rateid IN ($RateIdsCoseList)"
     mydb eval $sql
     set sql "DELETE FROM rates WHERE id IN ($RateIdsCoseList)"
     mydb eval $sql
}

proc AddItem {RateId Type MenuId InventoryId Amount} {
     set sql "INSERT INTO rate_items (rateid, type, menuid, inventoryid, amount) VALUES ($RateId, '$Type', $MenuId, $InventoryId, $Amount)"
     DbgPrint $sql
     mydb eval $sql
}

proc RemoveItem {RateItemIds} {     
     set sql "DELETE FROM rate_items WHERE id IN ([join $RateItemIds ","])"
     mydb eval $sql
}

proc Id {Desc} {
     set sql "SELECT id FROM rates WHERE desc = '$Desc'"
     return [Q1 $sql]
}

proc BuyOutAmount {MenuItemId} {     
     set RateId [Id [MenuNS::Desc $MenuItemId]]
     set sql "SELECT amount FROM rate_items WHERE rateid = $RateId AND type = 'buy-out'"
     return [Q1 $sql]
}

proc ListRates {} {
     set sql "SELECT id, desc FROM rates"
     set Results [mydb eval $sql]
}

proc ListRateItems {RateIds} {
     set sql "SELECT * FROM rate_items WHERE rateid IN ([join $RateIds ","])"
     set Results [Raise [mydb eval $sql] 6]
     set Out {}
     foreach Element $Results {
          puts "Element = $Element"
          set Id [lindex $Element 0]
          set RateId [lindex $Element 1]
          set MenuId [lindex $Element 2]
          set InventoryId [lindex $Element 3]
          set Type [lindex $Element 4]
          set Amount [lindex $Element 5]
          
          set MenuDesc [Q1 "SELECT desc FROM menu_items WHERE id = $MenuId"]
          set InventoryDesc [Q1 "SELECT desc FROM inventories WHERE id = $InventoryId"]
          lappend Out [list $Id $Type $MenuDesc $InventoryDesc $Amount]
     }
     return $Out
}

}