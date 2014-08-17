package provide interchange 1.0
package require sqlite3
package require gen

namespace eval AccountNS {

proc All {} {
     set sql "SELECT id FROM accounts"
     puts $sql
     return [mydb eval $sql]
}

proc Create {Desc InventoryId} {
     set sql "INSERT INTO accounts (desc, inventoryid) VALUES ('$Desc', $InventoryId)"
     mydb eval $sql
     puts $sql
     return [LastId accounts]
}

proc Delete {AccountIds} {
     set sql "DELETE FROM account_entries WHERE accountid IN ([join $AccountIds ","])"
     mydb eval $sql
     set sql "DELETE FROM accounts WHERE id IN ([join $AccountIds ","])"
     puts $sql
     mydb eval $sql
}

proc ChangeDesc {AccountId NewDesc} {
     set sql "UPDATE accounts SET desc = '$NewDesc' WHERE id = $AccountId"
     puts $sql
     mydb eval $sql
}

proc ChangeInventory {AccountId NewInventoryId} {
     set sql "UPDATE accounts SET inventoryid = $NewInventoryId WHERE id = $NewInventoryId"
     puts $sql
     mydb eval $sql
}

proc MakeEntry {AccountId LogId XactGroupId} {
     set sql "INSERT INTO account_entries (accountid, logid, xactgroupid) VALUES ($AccountId, $LogId, $XactGroupId)"
     puts $sql
     mydb eval $sql
     return [LastId account_entries]
}

proc ChangeEntry {EntryId ChangeType ToValue} {
     set sql "UPDATE account_entries SET $ChangeType = $ToValue WHERE id = $EntryId"
     puts $sql
     mydb eval $sql
}

proc EraseEntry {EntryIds} {
     set sql "DELETE FROM account_entries WHERE id IN ([join $EntryIds ","])"
     puts $sql
     mydb eval $sql
}

proc ListAccounts {} {
     set sql "SELECT x.id, x.desc, y.id, y.desc FROM accounts x JOIN inventories y ON x.inventoryid = y.id"
     puts $sql
     set Results [Raise [mydb eval $sql] 4]     
}

proc ListEntries {AccountIds} {
     set sql "SELECT x.id, y.notes FROM account_entries x JOIN xactgroup_info y ON x.xactgroupid = y.id WHERE x.accountid IN ([join $AccountIds ","])"
     puts $sql
     set Results [Raise [mydb eval $sql] 2]
}

}
