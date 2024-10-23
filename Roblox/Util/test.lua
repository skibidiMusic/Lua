local files = listfiles("sakso")
for i, v in files do
    print(i, v)
end
print(readfile("sakso/hi.txt"))

print(string.sub("hey", 1, 3))

print(string.find("/sadasd/sadasda/hey/asdasd.exe", "."))

