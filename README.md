### What it Does

This tool will generate the following on any EC11 or CS12 server for which it has access to `/etc/opscode/pivotal.pem`
* orgs
* users
* groups
* clients
* user-org associations

In addition, users will be populated into orgs and org admin groups at the rate specified in `setup.yml`.  Users, clients, and groups within an org will be added more-or-less randomly to the groups created by the tool.

It will capture everything it generates into one or more yml files
(currently just testdata/created-object.yml) so that this data can be
retrieved and compared compared after an upgrade or migration for any discrepencies.

### Usage

```bash
vagrant up
vagrant ssh
sudo -s
cd /vagrant
dpkg -i $private-chef-installer.deb
./setup.sh
```

Then on Enterprise Chef 11 and Chef Server 12:

```
./setup-ec.sh
(optionally run benchmark)
time ./benchmark.sh
```

On Open Source Chef Server 11:

```
./setup-osc.sh
```

#### Optional

- before running setup.sh, copy `setup.yml.example` to `setup.yml` and customize

#### Upgrade and Delta Capture (Work in Progress)

#### On the Guest ####
Once the above is complete, you'll need to capture the current state of
data for comparison after the upgrade. To do that, run:

First, capture the current state of the server for comparison
post-upgrade. To do that:

```bash
vagrant ssh
sudo -s
cd /vagrant
./pre-migration-backup.sh
```

After this is done (it will take a while), continue with:

```bash
sudo -s
private-chef-ctl stop
dpkg -i /vagrant/new-chef-server-core.deb
chef-server-ctl upgrade
chef-server-ctl start
```

Then capture the server state post-migration (again, this will take some
time):

```bash
./post-migration-backup.sh
```

#### On the Host ####

Run the diff.rb program to capture the diff.  This tool is currently aware of
the 11.x -> 12.x upgrade and does some diff suppression for things that are expected but
noisy. Perform the following from the repository root:

```bash
gem install easy_diff
ruby ./diff.rb  > testdata/delta.yml
```

The file `testdata/delta.yml` will contain the diff between pre- and post
upgrade.

#### Notes

- The default setting of 10 orgs takes a while, because we keep running
  out of precreated orgs under EC 11.  It still finishes, it just takes
  some retries. There is a private-chef.rb in this directory that you
  can copy in to /etc/opscode before initial reconfigure that will
  org precreation speed and depth.

### TODO

#### Short Term
- [ ] add support for setting custom acls, at minimum on groups but
      ideally across the range of supported objects.
- [ ] org invite creation and validation - is this in ec backup? (yes to
      2.x but what about 1.x? )
- [ ] OSC 11.2 support for data verification
- [ ] Better cookbook data generation
- [ ] Environments to OSC and EC data generation
- [ ] knife ec backup: better to have a ruby 2 install on this vm so
      that we can start with 2.x? Currently it's a little broken,
      getting ec installed.

#### Longer Term
- [ ] better directory structure. Better names for files...
- [ ] generate knife.rb for each created user/client. Directories for
  each?
- [ ] node creation and runlists
- [ ] simple cookbook generation and upload per-org
- [ ] as node client, grab the resolved runlist and make sure it's right
- [ ] diff tool - give it a gemfile, etc, etc.
- [ ] Diff handling: make diff handling smarter, with awareness of
  expected differences between two give versions.  Currently it's
  more-or-less hard-coded for EC11 -> CS12 but it should handle a
  reasonable range of from..target versions

#### TODONE
- [x] add support for creating clients per org
- [x] add support for creating groups
- [x] add support for group within group memebrshi
- [x] alt2 - can we just knife ec backup and compare before/after?
