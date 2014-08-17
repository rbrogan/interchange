package provide interchange 1.0
package require sqlite3
package require gen

namespace eval MenuNS {

proc Create {Desc} {
     set sql "INSERT INTO menu_items (desc) VALUES ('$Desc')"
     mydb eval $sql
     return [LastId menu_items]
}

proc Delete {MenuIds} {
     set sql "DELETE FROM menu_items WHERE id IN ([join $MenuIds ","])"
     mydb eval $sql
}

proc ChangeDesc {MenuId NewDesc} {
     set sql "UPDATE menu_items SET desc = '$NewDesc' WHERE id = $MenuId"
     mydb eval $sql
}

proc Id {Desc} {
     set sql "SELECT id FROM menu_items WHERE desc = '$Desc'"
     return [mydb eval $sql]
}

proc Desc {Id} {
     set sql "SELECT desc FROM menu_items WHERE id = $Id"
     return [Q1 $sql]
}

proc List {} {
     set sql "SELECT id, desc FROM menu_items"
     return [RunSelect $sql]
}

proc Show {MenuItemIds} {
     set sql "SELECT id, desc FROM menu_items WHERE id IN ([join $MenuItemIds ","])"
     return [RunSelect $sql]
}

proc CreateGroup {Desc} {
     set sql "INSERT INTO menu_groups (desc) VALUES ('$Desc')"
     mydb eval $sql
     return [LastId menu_groups]
}

proc DeleteGroup {Group} {
     if {[string is integer $Group]} {
          set WhereClause "id = $Group"
     } else {
          set WhereClause "desc = '$Group'"
     }
     set sql "DELETE FROM menu_groups WHERE $WhereClause"
     mydb eval $sql
}

proc AddToGroup {GroupId MenuIds} {
     set sql "SELECT menu_item_list FROM menu_groups WHERE id = $GroupId"
     set MenuItemList [Q1 $sql]
     lappend MenuItemList $MenuIds
     set sql "UPDATE menu_groups SET menu_item_list = '$MenuItemList'"
     mydb eval $sql
}

proc RemoveFromGroup {GroupId MenuIds} {
     set sql "SELECT menu_item_list FROM menu_groups WHERE id = $GroupId"
     set MenuItemList [Q1 $sql]
     
     foreach MenuId $MenuIds {
          set Index [lsearch $MenuItemList $MenuId]
          if {$Index != -1} {
               ListRemove MenuItemList $Index
          }
     }
     
     set sql "UPDATE menu_groups SET menu_item_list = '$MenuItemList'"
     mydb eval $sql     
}

proc ListInGroup {Group} {
     if {[string is integer $Group]} {
          set WhereClause "id = $Group"
     } else {
          set WhereClause "desc = '$Group'"
     }
     set sql "SELECT menu_item_list FROM menu_groups WHERE $WhereClause"
     return [Q1 $sql]
}

proc ShowGroup {Group} {
     set MenuItemIds [ListInGroup $Group]
     Show $MenuItemIds
}

}
