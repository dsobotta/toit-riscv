// Copyright (C) 2018 Toitware ApS.
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; version
// 2.1 only.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// The license can be found in the file `LICENSE` in the top level
// directory of this repository.

#pragma once

#include "../resource.h"
#include "../os.h"
#include "../top.h"

namespace toit {

class Timer;

typedef DoubleLinkedList<Timer> TimerList;

class Timer : public Resource, public TimerList::Element {
 public:
  TAG(Timer);
  Timer(ResourceGroup* resource_group)
    : Resource(resource_group)
    , _timeout(-1) { }

  ~Timer() {
    ASSERT(TimerList::Element::is_not_linked());
  }

  void set_timeout(int64_t timeout) { _timeout = timeout; }

  int64 timeout() const { return _timeout; }

 private:
  int64 _timeout;
};

class TimerEventSource : public EventSource, public Thread {
 public:
  static TimerEventSource* instance() { return _instance; }

  TimerEventSource();
  ~TimerEventSource();

  void on_unregister_resource(Locker& locker, Resource* r) override;

  void arm(Timer* timer, int64_t timeout);

 private:
  void entry() override;

  static TimerEventSource* _instance;

  ConditionVariable* _timer_changed;
  TimerList _timers;
  bool _stop;
};

} // namespace toit
