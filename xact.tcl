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

proc Show {XactGroupId} {
     set sql "SELECT accountentryid FROM xacts WHERE xactgroupid = $XactGroupId"
     
}

}
