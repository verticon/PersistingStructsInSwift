# PersistingStructsInSwift
The purpose of this playground is to demonstrate a simple technique for persisting structs.
The motivation of the technique arises from the fact that swift's struct types cannot adopt
the NSCoding protocol and thus NSKeyedArchiver is not available. Inspiration was provided
by [The Red Queen Coder](http://redqueencoder.com/property-lists-and-user-defaults-in-swift/) (TL;DR)
