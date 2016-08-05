cerner_splunk_ingredient Cookbook
=================================
Resource cookbook which provides custom resources for installing and managing Splunk.

These resources can:
- Install Splunk via downloadable package or archive
- Start and stop the Splunk service

Requirements
------------
Chef >= 12.4
Ruby >= 2.1.8

Supports Linux and Windows based systems with package support for Debian, Redhat,
and Windows.

Using resources of this cookbook to install and run Splunk means you agree to Splunk's EULA packaged with the software,
also available online at http://www.splunk.com/en_us/legal/splunk-software-license-agreement.html

---

Resources
---------

### splunk_install
Manages an installation of Splunk

##### Action *:install*
Installs Splunk or Universal Forwarder.

Properties:

| Name     |               Type(s)               | Required | Default                                                                   | Description                                                                                                                                                                                                                                                            |
|:---------|:-----------------------------------:|:--------:|:--------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| package  | `:splunk` or `:universal_forwarder` | **Yes**  |                                                                           | Specifies the Splunk package to install. You must specify the package, or name the resource for the package; for example, `package :splunk` or `splunk_install 'universal_forwarder' do ... end`                                                                       |
| version  |               String                | **Yes**  |                                                                           | Version of Splunk to install                                                                                                                                                                                                                                           |
| build    |               String                | **Yes**  |                                                                           | Build number of the version                                                                                                                                                                                                                                            |
| user     |               String                |    No    | Current user, or based on the package (`'splunk'` or `'splunkforwarder'`) | User that should own the splunk installation. Make sure you don't use a different user for running Splunk that has insufficient read/write access, or Splunk won't start!                                                                                              |
| base_url |               String                |    No    | `'https://download.splunk.com/products'`                                  | Base url to pull Splunk packages from. Use this if you are mirroring the downloads for Splunk packages. The resource will append the version, os, and filename to the url like so: `{base_url}/splunk/releases/0.0.0/linux/splunk-0.0.0-a1b2c3d4e5f6-Linux-x86_64.tgz` |

##### Action *:uninstall*
Removes Splunk or Universal Forwarder and all its configuration.

Properties:

| Name    |               Type(s)               | Required | Default | Description                                                                                                                                                                                        |
|:--------|:-----------------------------------:|:--------:|:--------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| package | `:splunk` or `:universal_forwarder` | **Yes**  |         | Specifies the Splunk package to uninstall. You must specify the package, or name the resource for the package; for example, `package :splunk` or `splunk_install 'universal_forwarder' do ... end` |


### splunk_service
Manages an installation of Splunk

**The following actions share the same properties:**

##### Action *:start*
Starts the Splunk daemon if not already running.
If the ulimit is changed, invokes a restart of the daemon at the end of the run.

##### Action *:restart*
Restarts the Splunk daemon, or starts it if not already running.

Properties:

| Name    |               Type(s)               | Required | Default                                                         | Description                                                                                                                                                                                      |
|:--------|:-----------------------------------:|:--------:|:----------------------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| package | `:splunk` or `:universal_forwarder` | **Yes**  |                                                                 | Specifies the Splunk package to install. You must specify the package, or name the resource for the package; for example, `package :splunk` or `splunk_install 'universal_forwarder' do ... end` |
| user    |               String                |    No    | Owner of the specified Splunk installation, or the current user | User to run Splunk as. This is the user that will be used to run the Splunk service.                                                                                                             |
| ulimit  |               Integer               |    No    | Start up script ulimit or user ulimit                           | Open file ulimit to give Splunk. This sets the ulimit in the start up script (if it exists) and for the given user in `/etc/security/limits.d/`. -1 translates to `'unlimited'`                  |

##### Action *:stop*
Stop the Splunk daemon if it is running.


Properties:

| Name    |               Type(s)               | Required | Default | Description                                                                                                                                                                                      |
|:--------|:-----------------------------------:|:--------:|:--------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| package | `:splunk` or `:universal_forwarder` | **Yes**  |         | Specifies the Splunk package to install. You must specify the package, or name the resource for the package; for example, `package :splunk` or `splunk_install 'universal_forwarder' do ... end` |

---

Contributing
------------

Check out the [Github Guide to Contributing](https://guides.github.com/activities/contributing-to-open-source/)
for some basic tips on contributing to open source projects, and make sure to read our [Contributing Guidelines](CONTRIBUTING)
before submitting an issue or pull request.

License and Authors
-------------------
- Author:: Alec Sears (alec.sears@cerner.com)

```text
Copyright:: 2016, Cerner Innovation, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
