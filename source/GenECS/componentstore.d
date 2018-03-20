module GenECS.componentstore;

import GenECS.utils;

import std.algorithm.comparison;
import std.conv;

alias ulong EntityID;
alias ulong EntityType;
alias ulong SystemKey;

class ComponentStore(Component, size_t ownId)
{
	struct Range
	{
		public this(size_t first)
		{
			this.first = cast(uint)(first);
			this.count = 0;
		}

		public uint first;
		public uint count;
	};

	// Guaranteed to be sorted by offset.
	private EntityType[] _rangeKeys;
	private Range[] _ranges;

	public SOA!(Component) _components;
	private size_t _count = 0;

	public this(size_t capacity)
	{
		_components = SOA!(Component)(capacity);
	}

	// Access component data for read-write access.
	public T[] ReadWrite(SystemKey key, T, string field)()
	{
		static if (key == ownId)
		{
			mixin("return _components."~field~"[0 .. _count];");
		}
		else
		{
			T[] ret;
			foreach (i, k; _rangeKeys)
			{
				if ((key & k) == key)
				{
					const Range r = _ranges[i];
					mixin("ret ~= _components."~field~"[r.first .. r.first + r.count];");
				}
			}
			return ret;
		}
	}

	// Access component data for read-only access.
	public const(T)[] Read(SystemKey key, T, string field)()
	{
		return cast(const T[])(ReadWrite!(key, T, field));
	}

	// Access component data for write-only access.
	public T[] Write(SystemKey key, T, string field)()
	{
		static if (key == ownId)
		{
			mixin("return _components."~field~"[0 .. _count];");
		}
		else
		{
			size_t count = 0;
			foreach (i, k; _rangeKeys)
			{
				if ((key & k) == key)
				{
					const Range r = _ranges[i];
					count += r.count;
				}
			}
			return new T[count];
		}
	}

	public void Feedback(SystemKey key, string field, T)(T[] arr)
	{
		static if (key != ownId)
		{
			import core.stdc.string;

			size_t src = 0;
			foreach (i, k; _rangeKeys)
			{
				if ((key & k) == key)
				{
					const Range r = _ranges[i];
					mixin("memcpy(&_components."~field~"[r.first], &arr[src], r.count * T.sizeof);");
					src += r.count;
				}
			}
		}
	}

	public void Add()(EntityType type)
	{
		if (type & ownId)
		{
			const size_t rangeIdx = FindRange(type);
			for (size_t i = signed(_ranges.length) - 1; i > rangeIdx; --i)
			{
				Range* r = &_ranges[i];
				auto last = r.first + max(0, signed(r.count) - 1);
				_components.Copy(r.first, last);
				++r.first;
			}

			Range* r = &_ranges[rangeIdx];
			++r.count;

			++_count;
		}
	}

	// Returns the index of the range associated with a key.
	private size_t FindRange()(EntityType type)
	{
		foreach (i, k; _rangeKeys)
		{
			if (k == type)
			{
				return i;
			}
		}
		_rangeKeys ~= type;
		_ranges ~= Range(_count);
		return _ranges.length - 1;
	}

	public void Print()
	{
		import std.stdio;
		//write(Component.stringof, ": ");
		for (size_t i = 0; i < _ranges.length; ++i)
		{
			for (size_t j = 0; j < _ranges[i].count; ++j)
			{
				write(_rangeKeys[i], ",");
			}
		}
		writeln();
	}

	public void Verify() const
	{
		size_t curr = 0;
		foreach (range; _ranges)
		{
			assert(range.first == curr);
			curr += range.count;
		}
	}
}