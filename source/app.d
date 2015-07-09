import std.stdio;

import task_theft;

void main()
{
	auto testTask = task!computeSomeStuff(2, 3, 4);

	testTask.execute.writeln;

	auto t0 = task!doStuff_1(4, 2);
	auto t1 = task!doStuff_2(1, "asd", 3.4);
	auto t2 = task!doStuff_2(4, "asd", 3.14);
	auto t3 = task!doStuff_3(4, "asd", "qwerty");

	auto q = make_queue!56();

	// Prints: Slot size: 56LU, queue size: 1824LU
	pragma(msg, "Slot size: ", q.Slot.sizeof, ", queue size: ", q.sizeof);

	//q.add( cast(void[0])[] );
	//q.add(5);
	q.enqueue(t0);
	q.enqueue(t1);
	q.enqueue(t1);
	q.enqueue(t2);
	q.enqueue(t3);

	while (!q.empty())
	{
		q.executeNext();
	}

	"All done!".writeln();
}

float computeSomeStuff(float a, float b, float c)
{
	return (a + b) * c;
}

void doStuff_1(int x, int y)
{
	"%s %s".writefln(x, y);
}

void doStuff_2(int a, string b, double c)
{
	"%s %s %s".writefln(a, b, c);
}
void doStuff_3(int a, string b, string c)
{
	"%s %s %s".writefln(a, b, c);
}
