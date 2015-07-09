module task_theft.queue;

//import std.parallelism;

import task_theft.task : VoidTask, Task;
import task_theft.container_primiteves : QueueMix;
import task_theft.spin_lock;

struct Queue(short TaskSize, size_t Length)
{
	union Slot
	{
		VoidTask as_task;
		void[TaskSize] as_raw_data;
	}

	Slot[Length] storage;

	shared SpinLock queue_lock;

	mixin QueueMix!(storage,
		blockUntilCapcityAvilable,
		lock,
		Length % 2 == 0);

	void blockUntilCapcityAvilable() { }

	LockGuard!SpinLock lock()
	{
		return LockGuard!SpinLock(queue_lock);
	}

	template enqueue(TaskInst)
	{
		import std.traits : fullyQualifiedName;
		import std.conv : to;

		static assert(is(TaskInst == Task!(T), T...),
			"we only accept tasks (aka `" ~ fullyQualifiedName!(Task) ~ "`) " ~
			"in this queue. Not `" ~ U.stringof ~ "`.");

		static assert(TaskInst.sizeof <= TaskSize,
			"Hey, looks like you're trying to submit a task " ~
			"that can't fit in this queue.\nTry increasing the " ~
			fullyQualifiedName!(TaskSize) ~ " template parameter to " ~
			"at least " ~ TaskInst.sizeof.to!string ~ " bytes.");

		union TaskSlot
		{
			TaskInst task;
			Slot slot;
		}

		void enqueue(auto ref TaskInst task)
		{
			auto to_add = TaskSlot(task);

			this.pushBack(to_add.slot);
		}
	}

	void executeNext()
	{
		auto current = this.getAndPopFront();

		current.as_task.execute();
	}


}

auto make_queue(short TaskSize = 8, size_t Length = 32)()
{
	return Queue!(TaskSize, Length)();
}

