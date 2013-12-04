require 'spec_helper'

describe Celluloid::StackDump do
  let(:actor_system) do
    Celluloid::ActorSystem.new
  end

  subject do
    actor_system.stack_dump
  end

  class BlockingActor
    include Celluloid

    def blocking
      Kernel.sleep
    end
  end

  before(:each) do
    Celluloid::Task.registry.each do |type,_|
      actor_klass = Class.new(BlockingActor) do
        dispatch_with type
      end
      actor = actor_system.within do
        actor_klass.new
      end
      actor.async.blocking
    end

    @idle_thread = actor_system.get_thread do
    end
    @active_thread = actor_system.get_thread do
      sleep
    end
    @active_thread.role = :other_thing

    sleep 0.01
  end

  describe '#actors' do
    it 'should include all actors' do
      subject.actors.size.should == actor_system.running.size
    end
  end

  describe '#threads' do
    it 'should include threads that are not actors' do
      subject.threads.size.should == 3
    end

    it 'should include idle threads' do
      subject.threads.map(&:thread_id).should include(@idle_thread.object_id)
    end

    it 'should include threads checked out of the pool for roles other than :actor' do
      subject.threads.map(&:thread_id).should include(@active_thread.object_id)
    end

    it 'should have the correct roles' do
      subject.threads.map(&:role).should include(nil, :other_thing, :task)
    end
  end
end
