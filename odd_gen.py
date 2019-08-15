class odd_numbers(object):
  def __init__(self, maximum):
    self.maximum = maximum

  def __iter__(self):
    return odd_iter(self)

class odd_iter(object):
  def __init__(self, container):
    self.container = container
    self.n = -1

  def __next__(self):
    self.n += 2
    if self.n > self.container.maximum:
      raise StopIteration
    return self.n

  def __iter__(self):
    return self

num = odd_numbers(32765)
print(list(num))
