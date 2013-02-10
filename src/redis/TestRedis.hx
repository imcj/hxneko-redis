/**
   Copyright (c) 2010-2013 SoybeanSoft, Ian Martins

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation
   files (the "Software"), to deal in the Software without
   restriction, including without limitation the rights to use,
   copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following
   conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.
   *
   * haXe/Neko RedisAPI
   * @author Ian Martins
   */

package redis;

import neko.net.Socket;
import neko.net.Host;
// TODO expire, expireAt, ttl, sort
// skipped select, move, flushdb, flushall, save, auth, backgroundsave, lastsave, shutdown, info, slaveof

class TestRedis extends haxe.unit.TestCase
{
    // shared database object to use for all tests
    private var db : Redis;

    // connect and clear the db, use index 10 for tests
    override public function setup()
    {
        db = new Redis("localhost");
        db.select(10);
        db.flushDB();
    }

    // close connection
    override public function tearDown()
    {
        db.quit();
    }

    public function testPing()
    {
        assertTrue(db.ping());
    }

    public function testSetExistsGetDel()
    {
        assertFalse(db.exists("somekey"));
        assertTrue(db.set("somekey", "a value"));
        assertEquals("a value", db.get("somekey"));
        assertEquals(1, db.delete(["somekey"]));
        assertFalse(db.exists("somekey"));
        assertEquals(null, db.get("somekey"));
    }

    public function testBinarySetGet()
    {
        assertTrue(db.set("somekey", "a\r\nmultiline\r\nvalue"));
        assertEquals("a\r\nmultiline\r\nvalue", db.get("somekey"));
    }

    public function testType()
    {
        assertTrue(db.set("key", "val1"));
        assertTrue(db.setsAdd("set", "val2"));
        assertEquals(1, db.listsLeftPush("list", "val3"));
        assertEquals("string", db.type("key"));
        assertEquals("set", db.type("set"));
        assertEquals("list", db.type("list"));
    }

    public function testKeys()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.setsAdd("key2", "val2"));
        assertEquals(1, db.listsLeftPush("list", "val3"));
        assertEquals("[key1,key2]", Std.string(sorted(db.keys("*key*"))));
    }

    public function testRandomKey()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        var ret = db.randomKey();
        assertTrue(ret == "key1" || ret == "key2");
    }

    public function testRename()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertTrue(db.rename("key1", "key2"));
        assertEquals("val1", db.get("key2"));
    }  

    public function testRenameSafely()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertFalse(db.renameSafely("key1", "key2"));
        assertTrue(db.renameSafely("key1", "key3"));
        assertEquals("val2", db.get("key2"));
        assertEquals("val1", db.get("key3"));
    }  

    public function testDbSize()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertEquals(2, db.dbSize());
        assertTrue(db.set("key3", "val3"));
        assertEquals(3, db.dbSize());
    }  

    public function testGetSet()
    {
        assertTrue(db.set("key1", "val1"));
        assertEquals("val1", db.getSet("key1", "val2"));
        assertEquals("val2", db.get("key1"));
    }

    public function testMultiGet()
    {
        assertTrue(db.set("key1", "val1"));
        assertTrue(db.set("key2", "val2"));
        assertTrue(db.set("key3", "val3"));
        assertEquals("[val1,val2,val3]", Std.string(db.multiGet(["key1", "key2", "key3"])));
    }

    public function testSetSafely()
    {
        assertTrue(db.set("key1", "val1"));
        assertFalse(db.setSafely("key1", "val2"));
        assertEquals("val1", db.get("key1"));
    }

    public function testMultiSet()
    {
        var fields = new Hash<String>();
        fields.set("key1", "val1");
        fields.set("key2", "val2");
        fields.set("key3", "val3");
        assertTrue(db.multiSet(fields));
        assertEquals("val1", db.get("key1"));
        assertEquals("val2", db.get("key2"));
        assertEquals("val3", db.get("key3"));
    }

    public function testMultiSetSafely()
    {
        assertTrue(db.set("key2", "value"));
        var fields = new Hash<String>();
        fields.set("key1", "val1");
        fields.set("key2", "val2");
        fields.set("key3", "val3");
        assertFalse(db.multiSetSafely(fields));
        assertFalse(db.exists("key1"));
        assertEquals("value", db.get("key2"));
        assertFalse(db.exists("key3"));
    }

    public function testIncrement()
    {
        assertTrue(db.set("key1", "1"));
        assertEquals(2, db.increment("key1"));
        assertEquals(3, db.increment("key1"));
    }

    public function testIncrementBy()
    {
        assertTrue(db.set("key1", "1"));
        assertEquals(3, db.incrementBy("key1", 2));
        assertEquals(6, db.incrementBy("key1", 3));
    }

    public function testDecrement()
    {
        assertTrue(db.set("key1", "10"));
        assertEquals(9, db.decrement("key1"));
        assertEquals(8, db.decrement("key1"));
    }

    public function testDecrementBy()
    {
        assertTrue(db.set("key1", "10"));
        assertEquals(8, db.decrementBy("key1", 2));
        assertEquals(5, db.decrementBy("key1", 3));
    }

    public function testAppend()
    {
        assertTrue(db.set("key1", "hello"));
        assertTrue(db.append("key1", " world"));
        assertEquals("hello world", db.get("key1"));
    }

    public function testSubstr()
    {
        assertTrue(db.set("key1", "some string"));
        assertEquals("string", db.substr("key1", 5, -1));
    }

    // lists

    public function testListsRightPushLengthRange()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals(3, db.listsLength("key1"));
        assertEquals("[1,2,3]", Std.string(db.listsRange("key1", 0, 3)));
    }

    public function testListsLeftPushLengthRange()
    {
        assertEquals(1, db.listsLeftPush("key1", "1"));
        assertEquals(2, db.listsLeftPush("key1", "2"));
        assertEquals(3, db.listsLeftPush("key1", "3"));
        assertEquals(3, db.listsLength("key1"));
        assertEquals("[3,2,1]", Std.string(db.listsRange("key1", 0, 3)));
    }

    public function testListsTrim()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertTrue(db.listsTrim("key1", 1, 2));
        assertEquals(2, db.listsLength("key1"));
        assertEquals("[2,3]", Std.string(db.listsRange("key1", 0, 1)));
    }

    public function testListsIndex()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals("1", db.listsIndex("key1", 0));
        assertEquals("2", db.listsIndex("key1", 1));
        assertEquals("3", db.listsIndex("key1", 2));
    }

    public function testListsSet()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertTrue(db.listsSet("key1", 1, "new"));
        assertEquals("[1,new,3]", Std.string(db.listsRange("key1", 0, 2)));
    }

    public function testListsRemove()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals(1, db.listsRemove("key1", 1, "2"));
        assertEquals("[1,3]", Std.string(db.listsRange("key1", 0, 1)));
    }


    public function testListsLeftPop()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals("1", db.listsLeftPop("key1"));
        assertEquals("[2,3]", Std.string(db.listsRange("key1", 0, 1)));
    }

    public function testListsRightPop()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals("3", db.listsRightPop("key1"));
        assertEquals("[1,2]", Std.string(db.listsRange("key1", 0, 1)));
    }

    public function testListsRightPopLeftPush()
    {
        assertEquals(1, db.listsRightPush("key1", "1"));
        assertEquals(2, db.listsRightPush("key1", "2"));
        assertEquals(3, db.listsRightPush("key1", "3"));
        assertEquals(1, db.listsRightPush("key2", "a"));
        assertEquals(2, db.listsRightPush("key2", "b"));
        assertEquals(3, db.listsRightPush("key2", "c"));
        assertEquals("3", db.listsRightPopLeftPush("key1", "key2"));
        assertEquals("[1,2]", Std.string(db.listsRange("key1", 0, 1)));
        assertEquals("[3,a,b,c]", Std.string(db.listsRange("key2", 0, 3)));
    }

    // sets

    private function sorted(arr :Array<String>)
    {
        arr.sort(function(a,b) return (a<b) ? -1 : (b<a) ? 1 : 0);
        return arr;
    }

    public function testSetsAddCountMembers()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertFalse(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertEquals(2, db.setsCount("key1"));
        assertEquals("[val1,val2]", Std.string(sorted(db.setsMembers("key1"))));
    }

    public function testSetsRemove()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key1", "val3"));
        assertEquals(3, db.setsCount("key1"));
        assertTrue(db.setsRemove("key1", "val2"));
        assertEquals(2, db.setsCount("key1"));
        assertEquals("[val1,val3]", Std.string(sorted(db.setsMembers("key1"))));
    }

    public function testSetsPop()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        var ret = db.setsPop("key1");
        assertTrue(ret == "val1" || ret == "val2");
        ret = db.setsPop("key1");
        assertTrue(ret == "val1" || ret == "val2");
        assertEquals(null, db.setsPop("key1"));
    }

    public function testSetsMove()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "vala"));
        assertTrue(db.setsAdd("key2", "valb"));
        assertTrue(db.setsMove("key1", "key2", "val1"));
        assertEquals("[val2]", Std.string(sorted(db.setsMembers("key1"))));
        assertEquals("[val1,vala,valb]", Std.string(sorted(db.setsMembers("key2"))));
    }

    public function testSetsHasMember()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsHasMember("key1", "val1"));
        assertTrue(db.setsHasMember("key1", "val2"));
        assertFalse(db.setsHasMember("key1", "val3"));
    }

    public function testSetsIntersect()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertEquals("[val1]", Std.string(sorted(db.setsIntersect(["key1", "key2"]))));
    }

    public function testSetsIntersectStore()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertTrue(db.setsIntersectStore("key3", ["key1", "key2"]));
        assertEquals("[val1]", Std.string(sorted(db.setsMembers("key3"))));
    }

    public function testSetsUnion()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertEquals("[val1,val2,val3]", Std.string(sorted(db.setsUnion(["key1", "key2"]))));
    }

    public function testSetsUnionStore()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertTrue(db.setsUnionStore("key3", ["key1", "key2"]));
        assertEquals("[val1,val2,val3]", Std.string(sorted(db.setsMembers("key3"))));
    }

    public function testSetsDifference()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertEquals("[val2]", Std.string(sorted(db.setsDifference(["key1", "key2"]))));
    }

    public function testSetsDifferenceStore()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        assertTrue(db.setsAdd("key2", "val1"));
        assertTrue(db.setsAdd("key2", "val3"));
        assertTrue(db.setsDifferenceStore("key3", ["key1", "key2"]));
        assertEquals("[val2]", Std.string(sorted(db.setsMembers("key3"))));
    }

    public function testSetsRandomMember()
    {
        assertTrue(db.setsAdd("key1", "val1"));
        assertTrue(db.setsAdd("key1", "val2"));
        var ret = db.setsRandomMember("key1");
        assertTrue(ret == "val1" || ret == "val2");
    }

    // sorted set

    public function testSortedSetsAddCount()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertEquals(3, db.sortedSetsCount("key1"));
        assertEquals("[val1,val2,val3]", Std.string(db.sortedSetsRange("key1", 0, 2)));
    }

    public function testSortedSetsRemove()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertTrue(db.sortedSetsRemove("key1", "val1"));
        assertEquals(2, db.sortedSetsCount("key1"));
        assertEquals("[val2,val3]", Std.string(db.sortedSetsRange("key1", 0, 1)));
    }

    public function testSortedSetsIncrementBy()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertEquals(4.0, db.sortedSetsIncrementBy("key1", 3, "val1"));
        assertEquals("[val2,val3,val1]", Std.string(db.sortedSetsRange("key1", 0, 2)));
    }


    public function testSortedSetsRank()
    {
        assertTrue(db.sortedSetsAdd("key1", 1.2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1.1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 1.3, "val3"));
        assertEquals(0, db.sortedSetsRank("key1", "val1"));
        assertEquals(1, db.sortedSetsRank("key1", "val2"));
        assertEquals(2, db.sortedSetsRank("key1", "val3"));
    }

    public function testSortedSetsRevRank()
    {
        assertTrue(db.sortedSetsAdd("key1", 1.2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1.1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 1.3, "val3"));
        assertEquals(2, db.sortedSetsReverseRank("key1", "val1"));
        assertEquals(1, db.sortedSetsReverseRank("key1", "val2"));
        assertEquals(0, db.sortedSetsReverseRank("key1", "val3"));
    }

    public function testSortedSetsReverseRange()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertEquals("[val3,val2,val1]", Std.string(db.sortedSetsReverseRange("key1", 0, 2)));
    }

    public function testSortedSetsRangeByScore()
    {
        assertTrue(db.sortedSetsAdd("key1", 2.1, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1.2, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3.3, "val3"));
        assertEquals("[val2,val3]", Std.string(db.sortedSetsRangeByScore("key1", 2, 4)));
    }

    public function testSortedSetsScore()
    {
        assertTrue(db.sortedSetsAdd("key1", 2.1, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1.1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3.1, "val3"));
        assertEquals(1.1, db.sortedSetsScore("key1", "val1"));
        assertEquals(2.1, db.sortedSetsScore("key1", "val2"));
        assertEquals(3.1, db.sortedSetsScore("key1", "val3"));
    }

    public function testSortedSetsRemoveRangeByRank()
    {
        assertTrue(db.sortedSetsAdd("key1", 2.1, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1.1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3.2, "val5"));
        assertTrue(db.sortedSetsAdd("key1", 3.0, "val3"));
        assertTrue(db.sortedSetsAdd("key1", 3.1, "val4"));
        assertEquals(3, db.sortedSetsRemoveRangeByRank("key1", 1, 3));
        assertEquals("[val1,val5]", Std.string(db.sortedSetsRange("key1", 0, -1)));
    }

    public function testSortedSetsRemoveByScore()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertEquals(2, db.sortedSetsRemoveRangeByScore("key1", 2, 3));
        assertEquals("[val1]", Std.string(db.sortedSetsRange("key1", 0, 1)));
    }

    public function testSortedSetsUnionStore()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2a"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1a"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3a"));
        assertTrue(db.sortedSetsAdd("key2", 5, "val2b"));
        assertTrue(db.sortedSetsAdd("key2", 4, "val1b"));
        assertTrue(db.sortedSetsAdd("key2", 6, "val3b"));
        assertEquals(6, db.sortedSetsUnionStore("result", ["key1", "key2"]));
        assertEquals("[val1a,val2a,val3a,val1b,val2b,val3b]", Std.string(db.sortedSetsRange("result", 0, -1)));
    }

    public function testSortedSetsUnionStoreAggMax()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val3"));
        assertTrue(db.sortedSetsAdd("key2", 5, "val2"));
        assertTrue(db.sortedSetsAdd("key2", 4, "val1"));
        assertTrue(db.sortedSetsAdd("key2", 6, "val3"));
        assertEquals(3, db.sortedSetsUnionStore("result", ["key1", "key2"], null, "max"));
        assertEquals("[val1,val2,val3]", Std.string(db.sortedSetsRange("result", 0, -1)));
    }

    public function testSortedSetsIntersectStore()
    {
        assertTrue(db.sortedSetsAdd("key1", 2, "val2"));
        assertTrue(db.sortedSetsAdd("key1", 1, "val1"));
        assertTrue(db.sortedSetsAdd("key1", 3, "val3"));
        assertTrue(db.sortedSetsAdd("key2", 5, "val3"));
        assertTrue(db.sortedSetsAdd("key2", 4, "val2"));
        assertTrue(db.sortedSetsAdd("key2", 6, "val4"));
        assertEquals(2, db.sortedSetsIntersectStore("result", ["key1", "key2"]));
        assertEquals("[val2,val3]", Std.string(db.sortedSetsRange("result", 0, -1)));
    }

    // hash

    public function testHashSetGet()
    {
        assertTrue(db.hashSet("key1", "field1", "val1"));
        assertEquals("val1", db.hashGet("key1", "field1"));
    }

    public function testHashSetSafely()
    {
        assertTrue(db.hashSetSafely("key1", "field1", "val1"));
        assertFalse(db.hashSetSafely("key1", "field1", "val2"));
        assertEquals("val1", db.hashGet("key1", "field1"));
    }

    public function testHashMultiSetGet()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        assertTrue(db.hashMultiSet("key1", fields));
        assertEquals("[val1,val2]", Std.string(db.hashMultiGet("key1", ["field1", "field2"])));
    }

    public function testHashIncrementBy()
    {
        assertTrue(db.hashSet("key1", "field1", "1"));
        assertEquals(3, db.hashIncrementBy("key1", "field1", 2));
        assertEquals("3", db.hashGet("key1", "field1"));
    }

    public function testHashExists()
    {
        assertTrue(db.hashSet("key1", "field1", "1"));
        assertTrue(db.hashExists("key1", "field1"));
    }

    public function testHashDelete()
    {
        assertTrue(db.hashSet("key1", "field1", "1"));
        assertTrue(db.hashExists("key1", "field1"));
        assertTrue(db.hashDelete("key1", "field1"));
        assertFalse(db.hashExists("key1", "field1"));
    }

    public function testHashLength()
    {
        assertTrue(db.hashSet("key1", "field1", "1"));
        assertEquals(1, db.hashLength("key1"));
        assertTrue(db.hashSet("key1", "field2", "2"));
        assertEquals(2, db.hashLength("key1"));
        assertTrue(db.hashDelete("key1", "field1"));
        assertEquals(1, db.hashLength("key1"));
    }

    public function testHashKeys()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hashMultiSet("key1", fields));
        assertEquals("[field2,field1,field3]", Std.string(db.hashKeys("key1")));
    }

    public function testHashValues()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hashMultiSet("key1", fields));
        assertEquals("[val2,val1,val3]", Std.string(db.hashValues("key1")));
    }

    public function testHashGetAll()
    {
        var fields = new Hash<String>();
        fields.set("field1", "val1");
        fields.set("field2", "val2");
        fields.set("field3", "val3");
        assertTrue(db.hashMultiSet("key1", fields));
        assertEquals("{field2 => val2, field1 => val1, field3 => val3}", Std.string(db.hashGetAll("key1")));
    }

    // sort

    public function testSortWordsFwdRev()
    {
        assertEquals(1, db.listsLeftPush("key1", "val2"));
        assertEquals(2, db.listsLeftPush("key1", "val1"));
        assertEquals(3, db.listsLeftPush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.listsRange("key1", 0, -1)));
        assertEquals("[val1,val2,val3]", Std.string(db.sort("key1", null, null, null, null, null, true)));
        assertEquals("[val3,val2,val1]", Std.string(db.sort("key1", null, null, null, null, false, true)));
    }

    public function testSortNums()
    {
        assertEquals(1, db.listsLeftPush("key1", "1.23"));
        assertEquals(2, db.listsLeftPush("key1", "1.01"));
        assertEquals(3, db.listsLeftPush("key1", "2.11"));
        assertEquals("[2.11,1.01,1.23]", Std.string(db.listsRange("key1", 0, -1)));
        assertEquals("[2.11,1.23,1.01]", Std.string(db.sort("key1", null, null, null, null, false, false)));
    }

    public function testSortLimit()
    {
        assertEquals(1, db.listsLeftPush("key1", "val2"));
        assertEquals(2, db.listsLeftPush("key1", "val1"));
        assertEquals(3, db.listsLeftPush("key1", "val5"));
        assertEquals(4, db.listsLeftPush("key1", "val3"));
        assertEquals("[val3,val5,val1,val2]", Std.string(db.listsRange("key1", 0, -1)));
        assertEquals("[val2,val3]", Std.string(db.sort("key1", null, 1, 2, null, null, true)));
    }

    public function testSortByExternalKeys()
    {
        assertTrue(db.set("w_val1", "1"));
        assertTrue(db.set("w_val2", "2"));
        assertTrue(db.set("w_val3", "3"));
        assertEquals(1, db.listsLeftPush("key1", "val2"));
        assertEquals(2, db.listsLeftPush("key1", "val1"));
        assertEquals(3, db.listsLeftPush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.listsRange("key1", 0, -1)));
        assertEquals("[val1,val2,val3]", Std.string(db.sort("key1", "w_*", null, null, null, null, true)));
    }

    public function testSortStore()
    {
        assertEquals(1, db.listsLeftPush("key1", "val2"));
        assertEquals(2, db.listsLeftPush("key1", "val1"));
        assertEquals(3, db.listsLeftPush("key1", "val3"));
        assertEquals("[val3,val1,val2]", Std.string(db.listsRange("key1", 0, -1)));
        assertEquals(3, db.sort("key1", null, null, null, null, null, true, "key2"));
        assertEquals("[val1,val2,val3]", Std.string(db.listsRange("key2", 0, -1)));
    }
}
