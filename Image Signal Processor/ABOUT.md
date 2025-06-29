  <p>
    The reason I started this project was because I have a fondness for microarchitecture. I like learning how computers work, and after tackling my custom CPU project, I wanted to dive into something that was more about throughput. I know many neural networks and ML nowadays require high throughput, and machines with large matrix multiplication capabilities, but i still wanted to implement something somewhat recognizable to me. I also wanted to practice around clock stability and consistent clock trees. From my last project, doing debugging I realized I wish my project was more modular, so verification of each part would be easier and I could focus on debugging one thing without breaking the other. I stepped up my game for this project, I wanted to develop a parallel processing machine. I chose a stream processor because of the long internal pipelines and lots of data transforms and imaging. I was also interested in the FIFO interconnects that helped deal with latency.
  </p>

  <p>
    I originally wanted to work on the Apple ISP pipeline, because people know what that is lol, but I chose to base around AMD vitis vision because of it being more accessible than the apple isp pipeline.
  </p>

  <p>
    The first step was to design a modular building block that would simplify all my debugging and pipelining in the future. This led to a long headache of me trying to figure out what buffer would be best, I am not sure if I came up with the best, but I came up with what worked. These FIFO shells would make sure data was ready to be written to or read and only pass data along based on that.
  </p>

  <p>
    The rest wasn't as hard, I just wanted to implement many structural multiplication and shifting modules, and emulate matrix multiplication because I know that many neural networks need that hardware to work. I wanted to be able to target these applications if I ever did a fpga project based on this.
  </p>

the isp_pipeline module contains a call for each of the pipeline stages. All of the blc_c_N modules can be found in blc_c.v, and same with the rest. 

  
</div>
