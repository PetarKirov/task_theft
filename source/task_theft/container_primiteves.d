module task_theft.container_primiteves;

mixin template QueueMix(alias QueueStorage, alias GrowthFunction,
	alias LockFunction, bool length_is_power_of_two = false)
{
	import std.range.primitives : hasLength, isRandomAccessRange, ElementType;
	import std.traits : isStaticArray;

	static assert (
		hasLength!(typeof(QueueStorage)) &&
		(
			isRandomAccessRange!(typeof(QueueStorage)) ||
			isStaticArray!(typeof(QueueStorage))
		),
		"QueueStorage should be a finite random-access range, not " ~
		typeof(QueueStorage).stringof);

	alias GrowthFuncType = void function();
	alias LockFuncType(L) = L function();

	static assert (is(typeof(&GrowthFunction) : GrowthFuncType),
		"GrowthFunction should be callable with no arguments!");

	//static assert (is(typeof(&LockFunction) : LockFuncType!L, L)); //,	"GrowthFunction should be callable with no arguments!");

	alias E = ElementType!(typeof(QueueStorage));

	protected
	{
		size_t start;
		size_t end;
		size_t count;
	}

	@property
	{
		bool empty() { return !count; }

		size_t length() { return count; }

		size_t capacity() { return QueueStorage.length; }

		auto ref E front()
		in { assert (!empty); }
		body {
			return QueueStorage[start];
		}

		auto ref E back()
		in { assert (!empty); }
		body {
			return this[count - 1];
		}
	}

	auto ref E opIndex(size_t idx)
	in { assert (idx < length); }
	body
	{
		auto place = (start + idx) % this.capacity;
		return QueueStorage[place];
	}

	void popFront()
	in { assert (!empty); } body
	{
		count--;

		static if (length_is_power_of_two)
			start = (start + 1) & (this.capacity - 1);
		else
			start = start + 1 != this.capacity ?
				start + 1 : 0;
	}

	E getAndPopFront()
	in { assert (!empty); } body
	{
		auto result = this.front;
		this.popFront();
		return result;
	}

	void popBack()
	in { assert (!empty); } body
	{
		count--;
		end = end - 1 != 0 ? end - 1 : this.capacity - 1;
	}

	void pushBack()(auto ref E val)
	{
		if (count == this.capacity)
			GrowthFunction();

		QueueStorage[end] = val;
		count++;

		static if (length_is_power_of_two)
			end = (end + 1) & (this.capacity - 1);
		else
			end = end + 1 != this.capacity ?
				end + 1 : 0;
	}

	enum Side
	{
		front,
		back,
	}

	void push(Side side)(auto ref E val)
	{
		static if (side == Side.back)
			this.pushBack(val);
		else
			this.pushFront(val);
	}

	E getPop(Side side)(auto ref E val)
	{
		static if (side == Side.front)
		{
			auto result = this.front;
			this.popFront();
			return result;
		}
		else
		{
			auto result = this.front;
			this.popFront();
			return result;
		}
	}

	static stealFrom(Side victimSide, Side stealerSide, V, S)
		(auto ref V victim, auto ref S stealer, float profit, Side side)
	{
		auto victim_lock = victim.lock();

		auto steal_count = cast(size_t)(victim.length * profit);

		foreach (_; 0 .. steal_count)
			stealer.push!stealerSide(
				victim.getPop!victimSide());

		// implicitly unlock the victim
	}
}

version (unittest)
{
	struct TestQueue(T)
	{
		enum default_capacity = 16;
		T[] data = new T[default_capacity];

		this(size_t initial_capacity)
		{
			data = new T[initial_capacity];
		}

		void grow()
		{
			import std.algorithm : max;
			auto new_size = max(data.length * 2, default_capacity);
			auto new_arr = new T[new_size];

			foreach (i; 0 .. this.length)
				new_arr[i] = this[i];

			this.data = new_arr;
			start = 0;
			end = length;
		}

		void lock() { }

		mixin QueueMix!(data, grow, lock, true);
	}

	auto make_queue(T)(size_t initial_size)
	{
		return TestQueue!T(initial_size);
	}
}

unittest
{
	auto q = make_queue!int(1);

	q.pushBack(1);
	assert (q.front == 1);
	assert (!q.empty);
	assert (q.length == 1);
	assert (q[0] == 1);

	q.popFront();
	assert (q.empty);
	assert (q.length == 0);

	q.pushBack(2);
	q.pushBack(3);
	assert (q.front == 2);
	assert (q.back == 3);
}

unittest
{
	auto q = make_queue!int(2);

	q.pushBack(42);
	assert (q.front == 42);
	assert (!q.empty);
	assert (q.length == 1);
	assert (q[0] == 42);
	assert (q.back == 42);

	q.popFront();
	assert (q.empty);
	assert (q.length == 0);

	q.pushBack(15);
	assert (q.front == 15);
	assert (!q.empty);
	assert (q.length == 1);
	assert (q[0] == 15);
	assert (q.back == 15);

	q.pushBack(16);
	assert (q.front == 15);
	assert (!q.empty);
	assert (q.length == 2);
	assert (q[0] == 15);
	assert (q[1] == 16);
	assert (q.back == 16);

	q.popFront();
	assert (q.front == 16);
	assert (!q.empty);
	assert (q.length == 1);
	assert (q[0] == 16);
	assert (q.back == 16);
}