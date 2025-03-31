import SwiftUI
import Virtualization

struct ContentView: View {
    @State private var vm: ArchLinuxVM?
    
    var body: some View {
        VStack {
            Text("Arch Linux VM")
                .font(.title)
            
            Button("Start VM") {
                startVM()
            }
            .padding()
        }
    }
    
    func startVM() {
        guard let isoURL = URL(string: "file://\(NSHomeDirectory())/Downloads/archlinux.iso") else {
            print("Arch Linux ISO not found.")
            return
        }
        
        let vm = ArchLinuxVM(isoPath: isoURL)
        self.vm = vm
        vm.start()
    }
}

class ArchLinuxVM {
    private var virtualMachine: VZVirtualMachine?
    
    init(isoPath: URL) {
        let config = VZVirtualMachineConfiguration()
        
        config.cpuCount = max(2, ProcessInfo.processInfo.processorCount / 2)
        config.memorySize = 4 * 1024 * 1024 * 1024  // 4GB RAM
        
        let diskURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Documents/archlinux_disk.img")
        if !FileManager.default.fileExists(atPath: diskURL.path) {
            let _ = FileManager.default.createFile(atPath: diskURL.path, contents: nil, attributes: nil)
            try? FileHandle(forWritingTo: diskURL).truncateFile(atOffset: 10 * 1024 * 1024 * 1024) // 10GB
        }
        
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: try! VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false))
        config.storageDevices = [blockDevice]
        
        let bootloader = VZEFIBootLoader()
        config.bootLoader = bootloader
        
        let network = VZVirtioNetworkDeviceConfiguration()
        network.attachment = VZNATNetworkDeviceAttachment()
        config.networkDevices = [network]
        
        let console = VZVirtioConsoleDeviceConfiguration()
        let serial = VZVirtioConsolePortConfiguration()
        console.ports.append(serial)
        config.consoleDevices = [console]
        
        let cdromAttachment = try! VZDiskImageStorageDeviceAttachment(url: isoPath, readOnly: true)
        let cdrom = VZVirtioBlockDeviceConfiguration(attachment: cdromAttachment)
        config.storageDevices.append(cdrom)
        
        try! config.validate()
        self.virtualMachine = VZVirtualMachine(configuration: config)
    }
    
    func start() {
        virtualMachine?.start { error in
            if let error = error {
                print("Failed to start VM: \(error)")
            } else {
                print("VM Started Successfully!")
            }
        }
    }
}

@main
struct ArchLinuxVMApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
