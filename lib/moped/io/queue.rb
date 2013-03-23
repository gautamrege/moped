# encoding: utf-8
module Moped
  module IO

    # A thread safe queue for use in the connection pool for getting
    # available connections.
    #
    # @since 2.0.0
    class Queue

      # Create a new queue.
      #
      # @example Create a new queue.
      #   Queue.new
      #
      # @since 2.0.0
      def initialize
        @mutex = Mutex.new
        @queue = []
        @resource = ConditionVariable.new
      end

      # Pop a connection off the queue.
      #
      # @example Pop a connection off the queue.
      #   queue.pop(0.25)
      #
      # @param [ Float ] timeout The time to wait, in seconds.
      #
      # @return [ Connection ] The next connection.
      #
      # @since 2.0.0
      def pop(timeout)
        mutex.synchronize do
          wait_for_next(Time.now + timeout)
        end
      end

      # Push a connection to the queue.
      #
      # @example Push a connection on the queue.
      #   queue.push(connection)
      #
      # @param [ Connection ] connection The connection to add.
      #
      # @since 2.0.0
      def push(connection)
        mutex.synchronize do
          queue.push(connection)
          resource.broadcast
        end
      end

      # Get the number of items in the queue.
      #
      # @example Get the number of items in the queue.
      #   queue.size
      #
      # @return [ Integer ] The number of items.
      #
      # @since 2.0.0
      def size
        mutex.synchronize do
          queue.size
        end
      end

      private

      # @!attribute mutex
      #   @return [ Mutex ] The queue's mutex.
      # @!attribute queue
      #   @return [ Array ] The internal array of items.
      # @!attribute resource
      #   @return [ ConditionVariable ] The condition variable.
      attr_reader :mutex, :queue, :resource

      # Wait for the next connection in the queue for the provided period of
      # time, if time passes and nothing is added returns nil.
      #
      # @api private
      #
      # @example Get the next item or wait.
      #   queue.wait_for_next(1)
      #
      # @param [ Float ] deadline The time to wait.
      #
      # @return [ Connection ] The next item.
      #
      # @since 2.0.0
      def wait_for_next(deadline)
        loop do
          return queue.pop unless queue.empty?
          wait = deadline - Time.now
          return nil if wait <= 0
          resource.wait(mutex, wait)
        end
      end
    end
  end
end
