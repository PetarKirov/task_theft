module task_theft.spin_lock;

import core.atomic : cas, atomicStore;

enum LockState : uint
{
	unlocked = 0,
	locked = 1
}

struct SpinLock
{
	shared uint state = LockState.unlocked;

	void lock() shared
	{
		while( !cas(&state, LockState.unlocked, LockState.locked) ) { }
	}

	void unlock() shared
	{
		atomicStore(state, LockState.unlocked);
	}
}

struct BrokenSpinLock
{
	shared LockState state = LockState.unlocked;
	
	void lock() shared
	{
		while(state != state.unlocked) { }
		state = LockState.unlocked;
	}
	
	void unlock() shared
	{
		state = LockState.unlocked;
	}
}

struct LockGuard(T)
{
	shared T* lockPtr;

	this(shared SpinLock* toLock)
	{
		this.lockPtr = toLock;

		lockRef.lock();
	}

	~this()
	{
		lockPtr.unlock();
	}
}
