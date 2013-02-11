package ;

import redis.Redis;
import neko.Lib;

/**
  * see http://redis.io/commands
  *
  * @author Guntur Sarwohadi
  * modified by Ian Martins
  */

class Main
{
	static function main() 
	{
		var redis = new Redis();
		trace("----- info -----");
		trace("info: " + redis.info());
		trace("--- end info ---");

        redis.select(10);                                   // select db 10
        redis.flushdb();                                    // clear db 10
        trace("cleared db 10");

		trace("does 'index' exists? " + redis.exists("index"));

        Lib.println("");
        trace("==============================");
        trace("Test string, key=index");
        trace("===============================");
        trace("add index 100   : " + redis.set("index", "100"));
        trace("get index       : " + redis.get("index"));
        trace("incr index      : " + redis.incr("index"));
        trace("get index       : " + redis.get("index"));
        trace("incrby index 20 : " + redis.incrby("index", 20));
        trace("get index       : " + redis.get("index"));

		trace("does 'index' exists now? " + redis.exists("index"));
        
        Lib.println("");
        trace("==============================");
        trace("Test list, key=animal");
        trace("==============================");
        trace("rpush animal snake    : " + redis.rpush("animal", "snake"));
        trace("lrange 0 -1 animal    : " + redis.lrange("animal", 0, -1));
        trace("rpush animal bullfrog : " + redis.rpush("animal", "bullfrog"));
        trace("lrange 0 -1 animal    : " + redis.lrange("animal", 0, -1));
        trace("rpush animal firefly  : " + redis.lpush("animal", "firefly"));
        trace("lrange 0 -1 animal    : " + redis.lrange("animal", 0, -1));
        trace("rpop animal           : " + redis.rpop("animal"));
        trace("lrange 0 -1 animal    : " + redis.lrange("animal", 0, -1));
        trace("lpop animal           : " + redis.lpop("animal"));
        trace("lrange 0 -1 animal    : " + redis.lrange("animal", 0, -1));
        trace("llen animal           : " + redis.llen("animal"));
		
        Lib.println("");
        trace("==============================");
        trace("Test set, key=heroes");
        trace("==============================");
        trace("sadd heroes wolverine         : " + redis.sadd("heroes", ["wolverine"]));
        trace("smembers heroes               : " + redis.smembers("heroes"));
        trace("sadd heroes cyclops deathpool : " + redis.sadd("heroes", ["cyclops", "deathpool"]));
        trace("smembers heroes               : " + redis.smembers("heroes"));
        trace("sadd heroes deathpool         : " + redis.sadd("heroes", ["deathpool"]));
        trace("smembers heroes               : " + redis.smembers("heroes"));

        Lib.println("");
        trace("==============================");
        trace("Test set, key=enemies");
        trace("==============================");
        trace("sadd enemies juggernaut sabertooth deathpool: " + redis.sadd("enemies", ["juggernaut", "sabertooth", "deathpool"]));
        trace("smembers enemies : " + redis.smembers("enemies"));
		
        Lib.println("");
		trace("==============================");
		trace("Test sets, keys=heroes,enemies");
		trace("==============================");
		trace("all characters           : " + redis.sunion(["heroes", "enemies"]));
		trace("double-agents characters : " + redis.sinter(["heroes", "enemies"]));
		trace("true heroes              : " + redis.sdiff(["heroes", "enemies"]));
		trace("true enemies             : " + redis.sdiff(["enemies", "heroes"]));
		
        redis.flushdb();                                    // clear db 10
	}
}
