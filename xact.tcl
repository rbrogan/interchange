package provide interchange 1.0
package require sqlite3
package require gen

namespace eval XactNS {

proc Create {{Desc 0} {AccountEntryIds 0}} {
     set NewXactGroupId [IncrDbGlobal xactgroupid]
     if {$AccountEntryIds != 0} {
          foreach AccountEntryId $AccountEntryIds {
               set sql "INSERT INTO xacts (xactgroupid, accountentryid) VALUES ($NewXactGroupId, $AccountEntryId)"
               mydb eval $sql
          }
     }    
     if {$Desc != 0} {
          set sql "INSERT INTO xactgroup_info (xactgroupid, notes) VALUES ($NewXactGroupId, '$Desc')"
     } else {
          set sql "INSERT INTO xactgroup_info (xactgroupid) VALUES ($NewXactGroupId)"
     }
     puts $sql
     mydb eval $sql
     return $NewXactGroupId
}

proc AddItem {XactGroupId AccountEntryId} {
     set sql "INSERT INTO xacts (xactgroupid, accountentryid) VALUES ($XactGroupId, $AccountEntryId)"
     puts $sql
     mydb eval $sql
     return [LastId xacts]
}

proc RemoveItem {XactGroupId AccountEntryId} {
     set sql "DELETE FROM xacts WHERE xactgroupid = $XactGroupId AND accountentryid = $AccountEntryId"
     mydb eval $sql
}

proc Delete {XactGroupIds} {
     set sql "DELETE FROM xacts WHERE xactgroupid IN ([join $XactGroupIds ","])"
     mydb eval $sql
     set sql "DELETE FROM xactgroup_info WHERE xactgroupid IN ([join $XactGroupIds ","])"
     mydb eval $sql
}

proc ChangeDesc {XactGroupId NewDesc} {
     set sql "UPDATE xactgroup_info SET notes = '$NewDesc' WHERE xactgroupid = $XactGroupId"
     mydb eval $sql
}

proc ListItems {XactGroupId} {
     set ItemList {}

     set sql "SELECT id, accountentryid FROM xacts WHERE xactgroupid = $XactGroupId"
     set Results [Raise [mydb eval $sql] 2]
     foreach Result $Results {
          set XactId [lindex $Result 0]
          set AccountEntryId [lindex $Result 1]
          set sql "SELECT logid FROM account_entries WHERE id = $AccountEntryId"
          set LogId [Q1 $sql]
          set LogEntry [InventoryNS::FetchLog $LogId]
          set InventoryId [lindex $LogEntry 1]
          set MenuId [lindex $LogEntry 2]
          set Type [lindex $LogEntry 3]
          set Amount [lindex $LogEntry 4]
          set Cuando [lindex $LogEntry 5]
          
          set InventoryDesc [InventoryNS::Desc $InventoryId]
          set MenuDesc [MenuNS::Desc $MenuId]
          
          lappend ItemList [list $XactId $InventoryDesc $MenuDesc $Type $Amount $Cuando]
     }
     return $ItemList
}

proc Show {XactGroupId} {
     puts [Q1 "SELECT notes FROM xactgroup_info WHERE xactgroupid = $XactGroupId"]
     PrintList [ListItems $XactGroupId]
}

}
