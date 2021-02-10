class MyClass:
    def __init__(self, string):
        self.string = string

    def updateData(self):
        self.string = "updated"
        #print(self)

    def getData(self):
        return self.string
