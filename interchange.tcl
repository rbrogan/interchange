package provide interchange 1.0
package require sqlite3
package require gen

namespace eval InterchangeNS {

proc InitializeDbTables {} {
     set TableList {accounts inventories inventory_info inventory_logs menu_items rates rate_items xacts xactgroup_info}
     foreach Item $TableList {
          if {[TableExists $TableName]} {
               mydb eval "DROP TABLE $TableName"
          }
     }
     mydb eval "CREATE TABLE accounts (id integer primary key, desc text, inventoryid integer)"
     mydb eval "CREATE TABLE inventories (id integer primary key, desc text)"
     mydb eval "CREATE TABLE inventory_info (id integer primary key, inventoryid integer, menuid integer, amount integer)"
     mydb eval "CREATE TABLE inventory_logs (id integer primary key, inventoryid integer, menuid integer, type text, amount integer, cuando text)"
     mydb eval "CREATE TABLE menu_items (id integer primary key, desc text)"
     mydb eval "CREATE TABLE rates (id integer primary key, desc text)"
     mydb eval "CREATE TABLE rate_items (id integer primary key, rateid integer, menuid integer, inventoryid integer, type text, amount integer)"
     mydb eval "CREATE TABLE xacts (id integer primary key, xactgroupid integer, accountentryid integer)"
     mydb eval "CREATE TABLE xactgroup_info (id integer primary key, xactgroupid integer, notes text)"
}

proc SetDbFilePath {FilePath} {
     sqlite3 mydb $FilePath
}

}
