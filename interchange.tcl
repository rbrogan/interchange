package provide interchange 1.0
package require sqlite3
package require gen

namespace eval InterchangeNS {

proc InitializeDbTables {} {
     set TableList {accounts account_entries inventories inventory_info inventory_logs menu_groups menu_group_info menu_items rates rate_items xacts xactgroup_info globals}
     foreach TableName $TableList {
          if {[TableExists $TableName]} {
               mydb eval "DROP TABLE $TableName"
          }
     }
     mydb eval "CREATE TABLE accounts (id integer primary key, desc text, inventoryid integer)"
     mydb eval "CREATE TABLE account_entries (id integer primary key, accountid integer, logid integer, xactgroupid integer)"
     mydb eval "CREATE TABLE inventories (id integer primary key, desc text)"
     mydb eval "CREATE TABLE inventory_info (id integer primary key, inventoryid integer, menuid integer, amount integer)"
     mydb eval "CREATE TABLE inventory_logs (id integer primary key, inventoryid integer, menuid integer, type text, amount integer, cuando text)"
     mydb eval "CREATE TABLE menu_groups (id integer primary key, menuid integer, groupid integer)"
     mydb eval "CREATE TABLE menu_group_info (id integer primary key, groupid integer, desc text)"
     mydb eval "CREATE TABLE menu_items (id integer primary key, desc text)"
     mydb eval "CREATE TABLE rates (id integer primary key, desc text)"
     mydb eval "CREATE TABLE rate_items (id integer primary key, rateid integer, menuid integer, inventoryid integer, type text, amount integer)"
     mydb eval "CREATE TABLE xacts (id integer primary key, xactgroupid integer, accountentryid integer)"
     mydb eval "CREATE TABLE xactgroup_info (id integer primary key, xactgroupid integer, notes text)"
     mydb eval "CREATE TABLE globals (id integer primary key, desc text, intvalue integer, textvalue text)"
     CreateDbGlobal xactgroupid integer
}

proc SetDbFilePath {FilePath} {
     sqlite3 mydb $FilePath
}

proc CreateXactFromRate {RateId {Desc 0}} {
     set XactGroupId [Xact::Create [RateNS::Desc $RateId]]
     
     set BuyOutInventoryId [Q1 "SELECT inventoryid FROM rate_items WHERE rateid = $RateId AND type = 'buy-out'"]
     set BuyMenuId [Q1 "SELECT menuid FROM rate_items WHERE rateid = $RateId AND type = 'buy-out'"]
     set BuyAmount [Q1 "SELECT amount FROM rate_items WHERE rateid = $RateId AND type = 'buy-out'"]
     set BuyOutAccountId [Q1 "SELECT id FROM accounts WHERE inventoryid = $BuyOutInventoryId"]
     
     set SellOutInventoryId [Q1 "SELECT inventoryid FROM rate_items WHERE rateid = $RateId AND type = 'sell-out'"]
     set SellMenuId [Q1 "SELECT menuid FROM rate_items WHERE rateid = $RateId AND type = 'sell-out'"]
     set SellAmount [Q1 "SELECT amount FROM rate_items WHERE rateid = $RateId AND type = 'sell-out'"]
     set SellOutAccountId [Q1 "SELECT id FROM accounts WHERE inventoryid = $SellOutInventoryId"]
     
     Reduce_Log_Account_Add $BuyOutInventoryId $BuyMenuId $BuyAmount $BuyOutAccountId $XactGroupId
     Increase_Log_Account_Add $BuyInInventoryId $BuyMenuId $BuyAmount $BuyInAccountId $XactGroupId
     Reduce_Log_Account_Add $SellOutInventoryId $SellMenuId $SellAmount $SellOutAccountId $XactGroupId
     Increase_Log_Account_Add $SellInInventoryId $SellMenuId $SellAmount $SellInAccountId $XactGroupId
     
     return $XactGroupId
}

proc Increase_Log_Account_Add {InventoryId MenuId Amount AccountId XactGroupId {Cuando 0}} {
     set LogId [InventoryNS::IncreaseAndLog $InventoryId $MenuId $Amount $Cuando]
     set AccountEntryId [AccountNS::MakeEntry $AccountId $LogId $XactGroupId]
     XactNS::AddItem $XactGroupId $AccountEntryId
}

proc Reduce_Log_Account_Add {InventoryId MenuId Amount AccountId XactGroupId {Cuando 0}} {
     set LogId [InventoryNS::ReduceAndLog $InventoryId $MenuId $Amount]
     set AccountEntryId [AccountNS::MakeEntry $AccountId $LogId $XactGroupId]
     XactNS::AddItem $XactGroupId $AccountEntryId
}

proc AccountMakeEntry_XactAddItem {AccountId LogId XactGroupId} {
     set AccountEntryId [AccountNS::MakeEntry $AccountId $LogId $XactGroupId]
     XactNS::AddItem $XactGroupId $AccountEntryId
}

}

