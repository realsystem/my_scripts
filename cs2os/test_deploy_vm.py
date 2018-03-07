from marvin.cloudstackTestCase import cloudstackTestCase
from marvin.lib.base import Account, VirtualMachine, ServiceOffering
from marvin.lib.utils import cleanup_resources
from marvin.lib.common import get_zone, get_domain, get_template
 
class TestDeployVM(cloudstackTestCase):
    """Test deploy a VM into a user account
    """
 
 
    @classmethod
    def setUpClass(cls):
        super(TestDeployVM, cls)
 
 
 
    def setUp(self):
        self.apiclient = self.testClient.getApiClient()
        self.testdata = self.testClient.getParsedTestDataConfig()
  
 
        # Get Zone, Domain and Default Built-in template
        self.domain = get_domain(self.apiclient)
        self.zone = get_zone(self.apiclient, self.testClient.getZoneForTests())
  
 
        self.testdata["mode"] = self.zone.networktype
        self.template = get_template(self.apiclient, self.zone.id, self.testdata["ostype"])
  
 
        #create a user account
        self.account = Account.create(
            self.apiclient,
            self.testdata["account"],
            domainid=self.domain.id
        )
 
        #create a service offering
        small_service_offering = self.testdata["service_offerings"]["small"]
        small_service_offering['storagetype'] = 'local'
        self.service_offering = ServiceOffering.create(
            self.apiclient,
            small_service_offering
        )
        #build cleanup list
        self.cleanup = [
            self.service_offering,
            self.account
        ]
 
 
    def tearDown(self):
        try:
            cleanup_resources(self.apiclient, self.cleanup)
        except Exception as e:
            self.debug("Warning! Exception in tearDown: %s" % e)
 
 
    def test_deploy_vm(self):
        """Test Deploy Virtual Machine
 
        # Validate the following:
        # - listVirtualMachines returns accurate information
        """
        self.debug(
            "templatess: %s"\
            % self.template
        )
 
        self.virtual_machine = VirtualMachine.create(
            self.apiclient,
            self.testdata["virtual_machine"],
            accountid=self.account.name,
            zoneid=self.zone.id,
            domainid=self.account.domainid,
            serviceofferingid=self.service_offering.id,
            templateid=self.template.id
        )
 
        list_vms = VirtualMachine.list(self.apiclient, id=self.virtual_machine.id)
 
        self.debug(
            "Verify listVirtualMachines response for virtual machine: %s"\
            % self.virtual_machine.id
        )
 
        self.assertEqual(
            isinstance(list_vms, list),
            True,
            "List VM response was not a valid list"
        )
        self.assertNotEqual(
            len(list_vms),
            0,
            "List VM response was empty"
        )
 
        vm = list_vms[0]
        self.assertEqual(
            vm.id,
            self.virtual_machine.id,
            "Virtual Machine ids do not match"
        )
        self.assertEqual(
            vm.name,
            self.virtual_machine.name,
            "Virtual Machine names do not match"
        )
        self.assertEqual(
            vm.state,
            "Running",
            msg="VM is not in Running state"
        )
