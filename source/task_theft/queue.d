module task_theft.queue;

//import std.parallelism;

import task_theft.task;
import task_theft.container_primiteves : QueueMix;

struct Queue(short TaskSize = 8, size_t Length = 256)
{
	union Slot { void[TaskSize] data; }

	Slot[Length] storage;
	int lock;

	mixin QueueMix!(storage, blockUntilCapcityAvilable, Length % 2 == 0);

	void blockUntilCapcityAvilable() { }

	template add(U)
	{
		import std.traits : fullyQualifiedName;
		import std.conv : to;

		static assert(is(U == Task!(T), T...),
			"we only accept tasks (aka `" ~ fullyQualifiedName!(Task) ~ "`) " ~
			"in this queue. Not `" ~ U.stringof ~ "`.");

		static assert(U.sizeof <= TaskSize,
			"Hey, looks like you're trying to submit a task " ~
			"that can't fit in this queue.\nTry increasing the " ~
			fullyQualifiedName!(TaskSize) ~ " template parameter to " ~
			"at least " ~ U.sizeof.to!string ~ " bytes.");

		void add(auto ref U task)
		{
			void[] raw = cast(void[])(&task)[0 .. 1];
			assert (raw.length == task.sizeof);

			Slot s = void;
			s.data[0 .. raw.length] = raw[];

			this.pushBack(s);
		}
	}
}

auto make_queue(short TaskSize = 8, size_t Length = 256)()
{
	return Queue!(TaskSize, Length)();
}

