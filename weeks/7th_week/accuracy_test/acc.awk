BEGIN {
  # Set true start and true end
  if (!ts || !te) {
    print "please set true start (ts) and true end (te)"
    exit
  }
  # Initialize array of possible hits across template
  tl = seqLen
  for (i = 1; i <= tl; i++)
    arr[i] = 0
}
!/^#/ {   # Iterate over the predictions generated with sblast
  s = $5
  e = $6
  for (i = s; i <= e; i++) {
    arr[i] = 1
  }
}
END {
  # True positives
  tp = 0
  for (i = ts; i <= te; i++) {
    tp += arr[i]
  }
  # False negatives
  l = te - ts + 1
  fn = l - tp
  # False positives
  fp = 0
  for (i = 1; i < ts; i++)
    fp += arr[i]
  for (i = te+1; i <= tl; i++)
    fp += arr[i]
  # Sensitivity
  sn = tp / (tp + fn)
  # Specificity
  sp = tp / (tp + fp)
  # Correlation coefficient, Haubold & Wiehe (2006), p. 122
  tn = tl - l
  n = tp * tn - fp * fn
  d = sqrt((tp + fp) * (tn + fn) * (tn + fp) * (tp + fn))
  cc = n / d
  printf("cc: %f\n", cc)
}
