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

proc CreateGroup {Desc {GroupId 0}} {
     if {$GroupId == 0} {
          set GroupId [IncrDbGlobal anygroupid]
     }
     set sql "INSERT INTO menu_group_info (groupid, desc) VALUES ($GroupId, '$Desc')"
     mydb eval $sql
     return [LastId menu_group_info]
}

proc DeleteGroup {Group} {
     if {[string is integer $Group]} {
          set WhereClause "groupid = $Group"
          set sql2 "DELETE FROM menu_group_info WHERE groupid = $Group"
     } else {
          set WhereClause "groupid = (SELECT groupid FROM menu_group_info WHERE desc = '$Group')"
          set sql2 "DELETE FROM menu_group_info WHERE desc = '$Group'"
     }
     set sql "DELETE FROM menu_groups WHERE $WhereClause"
     mydb eval $sql
     mydb eval $sql2
}

proc AddToGroup {GroupId MenuIds} {
     foreach MenuId $MenuIds {
          set sql "INSERT INTO menu_groups (menuid, groupid) VALUES ($MenuId, $GroupId)"
          mydb eval $sql
     }
}

proc RemoveFromGroup {GroupId MenuIds} {
     set sql "DELETE FROM menu_groups WHERE groupid = $GroupId AND menuid IN ([join $MenuIds ","])"
     mydb eval $sql
}

proc ListInGroup {Group} {
     if {[string is integer $Group]} {
          set WhereClause "groupid = $Group"
     } else {
          set WhereClause "groupid = (SELECT groupid FROM menu_group_info WHERE desc = '$Group')"
     }

     set sql "SELECT menuid, (SELECT desc FROM menu_items WHERE id = menuid) FROM menu_groups WHERE $WhereClause"
     return [Raise [mydb eval $sql] 2]
}

proc ShowGroup {Group} {
     PrintList [ListInGroup $Group]
}

}
