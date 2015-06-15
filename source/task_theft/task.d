module task_theft.task;

import std.traits : ReturnType;

auto task(alias Fun, Args...)(Args args)
{
	return Task!(Fun, Args)(args);
}

private enum TaskStatus : ubyte
{
	notStarted,
	inProgress,
	done
}

private struct VoidTask
{
	alias VoidFun = void function(void*);

	VoidFun executor;
	TaskStatus taskStatus = TaskStatus.notStarted;

	void execute()
	{
		executor(&this);
	}

	bool done() @property
	{
		return atomicReadUbyte(taskStatus) == TaskStatus.done;
	}
}

struct Task(alias Fun, Args...)
{
	VoidTask base = VoidTask(&execute_base_impl);

	static if (hasResult)
		ResultType result;

	Args args;

	this(Args args_) { this.args = args_; }

	ResultType execute() { return Fun(args); }

	private static void execute_base_impl(void* self)
	{
		auto typedSelf = cast(typeof(this)*) self;

		static if(is(ReturnType!Fun == void))
			Fun(typedSelf.args);
		else
			typedSelf.result = Fun(typedSelf.args);
	}

	alias ResultType = ReturnType!Fun;
	enum hasResult = !is(ResultType == void);
}

private void atomicSetUbyte(T)(ref T stuff, T newVal)
	if (__traits(isIntegral, T) && is(T : ubyte))
{
	import core.atomic;
	//core.atomic.cas(cast(shared) &stuff, stuff, newVal);
	atomicStore(*(cast(shared) &stuff), newVal);
}

private ubyte atomicReadUbyte(T)(ref T val)
	if (__traits(isIntegral, T) && is(T : ubyte))
{
	import core.atomic;
	return atomicLoad(*(cast(shared) &val));
}