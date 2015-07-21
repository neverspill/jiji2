# coding: utf-8

require 'encase'

module Jiji::Model::Notification
  class NotificationRepository

    include Encase
    include Jiji::Errors

    def get_by_id(notification_id)
      Notification.find(notification_id) \
      || not_found(Notification, id: notification_id)
    end

    def retrieve_notifications(
      filter_conditions = {}, sort_order = {}, offset = 0, limit = 20)
      sort_order = insert_default_sort_order(sort_order)
      query = Jiji::Utils::Pagenation::Query.new(
        filter_conditions, sort_order, offset, limit)
      query.execute(Notification).map { |x| x }
    end

    def count_notifications(filter_conditions = {})
      Notification.where(filter_conditions).count
    end

    def delete_notifications_of_rmt(before)
      Notification.where(
        :backtest_id  => nil,
        :timestamp.lt => before
      ).delete
    end

    private

    def insert_default_sort_order(sort_order)
      sort_order ||= {}
      sort_order[:timestamp] = :asc unless sort_order.include?(:timestamp)
      sort_order[:id] = :asc unless sort_order.include?(:id)
      sort_order
    end

  end
end