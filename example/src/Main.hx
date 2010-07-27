package ;

import redis.Redis;
import neko.Lib;

/**
 * ...
 * @author Guntur Sarwohadi
 */

class Main 
{
	
	static function main() 
	{
		var redis:Redis = new Redis();
		//trace("info: " + redis.info());
		
		var hasIndex:Bool = redis.exists("index");
		trace("does 'index' exists? " + hasIndex);
		
		if (!hasIndex)
		{
			trace("==============================");
			trace(" > Test string: 'index'");
			trace("==============================");
			trace("add 'index' -> 100: " + redis.set("index", "100"));
			trace("get 'index': " + redis.get("index"));
			trace("increment 'index': " + redis.increment("index"));
			trace("get 'index': " + redis.get("index"));
			trace("incrementBy 20 on 'index': " + redis.incrementBy("index", 20));
			trace("get 'index': " + redis.get("index"));
			trace("==============================");
			trace(" > End string test");
			trace("==============================");
		}
		
		var hasAnimal:Bool = redis.exists("animal");
		trace("does 'animal' exists? " + hasAnimal);
		
		if (!hasAnimal)
		{
			trace("==============================");
			trace(" > Test list: 'animal'");
			trace("==============================");
			trace("add 'animal' -> snake: " + redis.listsRightPush("animal", "snake"));
			trace(" > 'animal' list: " + redis.listsRange("animal", 0, -1));
			trace("add 'animal' -> bullfrog: " + redis.listsRightPush("animal", "bullfrog"));
			trace(" > 'animal' list: " + redis.listsRange("animal", 0, -1));
			trace("add 'animal' -> firefly: " + redis.listsLeftPush("animal", "firefly"));
			trace(" > 'animal' list: " + redis.listsRange("animal", 0, -1));
			trace("snake eats bullfrog: " + redis.listsRightPop("animal"));
			trace(" > 'animal' list: " + redis.listsRange("animal", 0, -1));
			trace("firefly dies from age: " + redis.listsLeftPop("animal"));
			trace(" > 'animal' list: " + redis.listsRange("animal", 0, -1));
			trace("'animal' count: " + redis.listsLength("animal"));
			trace("==============================");
			trace(" > End list 'animal'");
			trace("==============================");
		}
		
		var hasHeroes:Bool = redis.exists("heroes");
		trace("does 'heroes' exists? " + hasHeroes);
		var hasEnemies:Bool = redis.exists("enemies");
		trace("does 'enemies' exists? " + hasEnemies);
		
		if (!hasHeroes)
		{
			trace("==============================");
			trace(" > Test sets: 'heroes'");
			trace("==============================");
			trace("add 'heroes' -> wolverine: " + redis.setsAdd("heroes", "wolverine"));
			trace(" > 'heroes' sets: " + redis.setsMembers("heroes"));
			trace("add 'heroes' -> cyclops: " + redis.setsAdd("heroes", "cyclops"));
			trace(" > 'heroes' sets: " + redis.setsMembers("heroes"));
			trace("add 'heroes' -> deathpool: " + redis.setsAdd("heroes", "deathpool"));
			trace(" > 'heroes' sets: " + redis.setsMembers("heroes"));
			trace("==============================");
			trace(" > End sets 'heroes'");
			trace("==============================");
		}
		
		if (!hasEnemies)
		{
			trace("==============================");
			trace(" > Test sets: 'enemies'");
			trace("==============================");
			trace("add 'enemies' -> juggernaut: " + redis.setsAdd("enemies", "juggernaut"));
			trace(" > 'enemies' sets: " + redis.setsMembers("enemies"));
			trace("add 'enemies' -> sabertooth: " + redis.setsAdd("enemies", "sabertooth"));
			trace(" > 'enemies' sets: " + redis.setsMembers("enemies"));
			trace("add 'enemies' -> deathpool: " + redis.setsAdd("enemies", "deathpool"));
			trace(" > 'enemies' sets: " + redis.setsMembers("enemies"));
			trace("==============================");
			trace(" > End sets 'enemies'");
			trace("==============================");
		}
		
		trace("==============================");
		trace(" > Test sets: 'heroes' & 'enemies'");
		trace("==============================");
		trace("double-agents characters: " + redis.setsIntersect(["heroes", "enemies"]));
		trace("all characters: " + redis.setsUnion(["heroes", "enemies"]));
		trace("true heroes: " + redis.setsDifference(["heroes", "enemies"]));
		trace("true enemies: " + redis.setsDifference(["enemies", "heroes"]));
		
		trace("removing 'index': " + redis.delete(["index"]));
		trace("removing 'animal': " + redis.delete(["animal"]));
		trace("removing 'heroes': " + redis.delete(["heroes"]));
		trace("removing 'enemies': " + redis.delete(["enemies"]));
	}
	
}