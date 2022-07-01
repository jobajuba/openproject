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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,1 MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative '../spec_helper'

describe 'Storage authorization', with_flag: { storages_module_active: true }, type: :feature, js: true do
  let(:permissions) { %i(view_work_packages edit_work_packages view_file_links) }
  let(:project) { create(:project) }
  let(:current_user) { create(:user, member_in_project: project, member_with_permissions: permissions) }
  let(:work_package) { create(:work_package, project:, description: 'Initial description') }
  let(:host) { 'http://example.com' }
  let(:storage) { create(:storage, host:) }
  let(:oauth_client) { create(:oauth_client, integration: storage) }
  let(:project_storage) { create(:project_storage, project:, storage:) }
  let(:file_link) { create(:file_link, container: work_package, storage:) }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }

  before do
    oauth_client
    project_storage
    file_link

    login_as current_user
    wp_page.visit_tab! :files
  end

  context 'when storage is configured and the storage login button is clicked', driver: :chrome_billy do
    before do
      proxy
        .stub("#{host}/apps/oauth2/authorize")
        .and_return(
          Proc.new do |params, _headers, _body, _url, _method|
            {
              code: 303,
              headers: {
                'Location' => "http://localhost:3001/oauth_clients/#{oauth_client.client_id}/callback?code=abc123&state=#{params['state']}"
              }
            }
          end
        )
    end

    it 'must call the authorization endpoint of the storage' do
      find('[data-qa-selector="op-files-tab--storage-info-box-button"]').click
    end
  end
end
