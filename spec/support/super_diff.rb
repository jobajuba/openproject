#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'super_diff/rspec-rails'

module SuperDiff
  module ObjectInspection
    module InspectionTreeBuilders
      class DateLike < Base
        def self.applies_to?(value)
          value.is_a?(Date)
        end

        def call
          InspectionTree.new do
            as_lines_when_rendering_to_lines(collection_bookend: :open) do
              add_text do |date|
                "#<#{date.class} "
              end

              when_rendering_to_lines do
                add_text "{"
              end
            end

            when_rendering_to_string do
              add_text do |date|
                date.strftime("%a %Y-%m-%d")
              end
            end

            when_rendering_to_lines do
              nested do |date|
                insert_separated_list(
                  %i[
                    year
                    month
                    day
                  ]
                ) do |name|
                  add_text name.to_s
                  add_text ": "
                  add_inspection_of date.public_send(name)
                end
              end
            end

            as_lines_when_rendering_to_lines(collection_bookend: :close) do
              when_rendering_to_lines do
                add_text "}"
              end

              add_text ">"
            end
          end
        end
      end
    end
  end
end

SuperDiff.configure do |config|
  # compress long diffs by eliding sections of unchanged data (data which is
  # present in both "expected" and "actual" values).
  config.diff_elision_enabled = true

  # By default the elision is pretty aggressive, set `diff_elision_maximum` to
  # preserve more of the unchanged lines in the diff.
  config.diff_elision_maximum = 5

  config.actual_color = :green
  config.expected_color = :red
  config.border_color = :yellow
  config.header_color = :yellow

  # Add support for Date objects
  config.add_extra_inspection_tree_builder_classes(SuperDiff::ObjectInspection::InspectionTreeBuilders::DateLike)
end
