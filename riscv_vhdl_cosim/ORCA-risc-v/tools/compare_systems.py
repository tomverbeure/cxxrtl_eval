#!/usr/bin/python
import sys
import shlex
import shutil
import os
import subprocess
import re
import time
import threading
###########################################################################
def pushd(dirname):
    class PushdContext:
        def __init__(self, dirname):
            self.cwd = os.path.realpath(dirname)
        def __enter__(self):
            self.original_dir = os.getcwd()
            os.chdir(self.cwd)
            return self
        def __exit__(self, type, value, tb):
            os.chdir(self.original_dir)

    return PushdContext(dirname)


QUEUES=("main.q",)
QUEUES=("main.q@altivec","main.q@asc","main.q@avx","main.q@cray1","main.q@mmx")#avoid star100
QUEUES=" ".join(map( lambda x : "-q "+ x,QUEUES))


class system:
    files_needed=("Makefile",
                  "riscv_hw.tcl",
                  "riscv_test.vhd",
                  "sevseg_conv.vhd",
                  "vblox1.qpf",
                  "vblox1.qsf",
                  "vblox1.qsys",
                  "vblox1.sdc")
    dirs=[]
    class duplicate_dir(Exception):
        pass
    def __init__(self,
                 branch_prediction,
                 btb_size,
                 divide_enable,
                 include_counters,
                 multiply_enable,
                 pipeline_stages,
                 shifter_single_cycle,
                 fwd_alu_only):
        self.branch_prediction=branch_prediction
        self.btb_size=btb_size
        self.divide_enable=divide_enable
        self.include_counters=include_counters
        self.multiply_enable=multiply_enable
        self.pipeline_stages=pipeline_stages
        self.shifter_single_cycle=shifter_single_cycle
        self.fwd_alu_only=fwd_alu_only
        self.dhrystones=""
        self.directory=("./veek_project_"+
                        "bp%s_"+
                        "btbsz%s_"+
                        "div%s_"+
                        "mul%s_"+
                        "count%s_"+
                        "pipe%s_"+
                        "ssc%s_"+
                        "fwd%s") %(self.branch_prediction,
                                   self.btb_size if self.branch_prediction == "true" else "0" ,
                                   self.divide_enable,
                                   self.multiply_enable,
                                   self.include_counters,
                                   self.pipeline_stages,
                                   self.shifter_single_cycle,
                                   self.fwd_alu_only)

        if self.directory in system.dirs:
            raise system.duplicate_dir;
        else:
            system.dirs.append(self.directory)

    def create_build_dir(self ):
        print "creating %s"%self.directory
        try:
            os.mkdir(self.directory)
        except:
            pass
        for f in system.files_needed :
            shutil.copy2("veek_project/"+f,self.directory)

        with open(self.directory+"/config.mk","w") as f:
            f.write('BRANCH_PREDICTION="%s"\n'   %self.branch_prediction)
            f.write('BTB_SIZE="%s"\n'            %self.btb_size)
            f.write('MULTIPLY_ENABLE="%s"\n'     %self.multiply_enable)
            f.write('DIVIDE_ENABLE="%s"\n'       %self.divide_enable)
            f.write('INCLUDE_COUNTERS="%s"\n'    %self.include_counters)
            f.write('PIPELINE_STAGES="%s"\n'     %self.pipeline_stages)
            f.write('SHIFTER_SINGLE_CYCLE="%s"\n'%self.shifter_single_cycle)
            f.write('FORWARD_ALU_ONLY="%s"\n'    %self.fwd_alu_only)
    def build(self,use_qsub=False,build_target="all"):
        make_cmd='make -C %s %s'%(self.directory,build_target)
        if use_qsub:
            qsub_cmd='qsub %s -b y -o %s -sync y -j y  -V -cwd -N "veek_project" '% (QUEUES, self.directory +"/build.log") + make_cmd
            proc=subprocess.Popen(shlex.split(qsub_cmd))
        else:
           proc=subprocess.Popen(shlex.split(make_cmd))
           proc.wait()
        return proc

    def run_dhrystone_sim(self,qsub):
        proc=subprocess.Popen(['true'])
        def replace(x,y):
            with open("vblox1/simulation/vblox1.vhd") as f:
                string=re.sub(x+r"\s*=> [0-9]+",x+" => "+y,f.read())
            with open("vblox1/simulation/vblox1.vhd","w") as f:
                f.write(string)


        if self.include_counters == "0":
            self.dhrystones="No Count"
            return proc
        if self.multiply_enable == "1" and self.divide_enable == "0":
            self.dhrystones="No Divide"
            return proc


        with pushd(self.directory):
            #these are modified versions of the benchmarks found in the riscv-test
            #repository. they only run 5 loops, all printf calls and setStats calls
            #are removed, and usertime is written to a gpio called hex0
            if self.multiply_enable == '1' :
                hex_file="../dhrystone.riscv.rv32im.gex"
            else:
                hex_file="../dhrystone.riscv.rv32i.gex"

            if not os.path.exists(hex_file):
                self.dhrystones="No Hex File"
                return proc

            if os.path.exists("vblox1/simulation"):
                shutil.rmtree("vblox1/simulation")
            shutil.copytree("../sim/vblox1/simulation","vblox1/simulation")


            shutil.copy(hex_file,"vblox1/simulation/mentor/test.hex")

            replace('BRANCH_PREDICTORS',self.btb_size if self.branch_prediction == "true" else '0')
            replace('MULTIPLY_ENABLE',self.multiply_enable)
            replace('DIVIDE_ENABLE',self.divide_enable)
            replace('INCLUDE_COUNTERS',self.include_counters)
            replace('PIPELINE_STAGES',self.pipeline_stages)
            replace('SHIFTER_SINGLE_CYCLE',self.shifter_single_cycle)
            replace('FORWARD_ALU_ONLY',self.fwd_alu_only)
            vsim_tcl=("do ../tools/runsim.tcl",
                      "add wave /vblox1/hex_0_external_connection_export",
                      "restart -f",
                      "onbreak {resume}",
                      "when {/vblox1/hex_0_external_connection_export /= x\"00000000\" } {stop}",
                      "run 200 us",
                      "puts \" User Time = [examine -decimal /vblox1/hex_0_external_connection_export ] \"",
                      "exit -f")
            with open("dhrystone.tcl","w") as f:
                f.write("\n".join(vsim_tcl))

            vsim_tcl=";".join(vsim_tcl)
            vsim_cmd="vsim -c -do dhrystone.tcl| tee dhrystone_sim.out"

            if qsub:
                queues=shlex.split(QUEUES)
                split_cmd=["qsub",]+queues+["-b","y","-sync","y","-j","y","-V","-cwd","-N","dsim",vsim_cmd]
                proc=subprocess.Popen(split_cmd)
            else:
               subprocess.call(vsim_cmd,shell=True)
            return proc

    def get_dhrystone_stats(self):
        out_file=self.directory+"/dhrystone_sim.out"
        if os.path.exists(out_file):
            out=open(out_file).read()
            user_time=re.findall(r"User Time = ([0-9]+)",out)[0]
            self.dhrystones=user_time
        return


    def get_build_stats(self):
        timing_rpt=self.directory+"/output_files/vblox1.sta.rpt"
        synth_rpt = self.directory+"/output_files/vblox1.map.rpt"
        fit_rpt=self.directory+"/output_files/vblox1.fit.rpt"
        self.fmax=-1
        self.cpu_prefit_size=-1
        self.cpu_postfit_size=-1
        if os.path.exists(timing_rpt):
            with open(timing_rpt) as f:
                rpt_string = f.read()
                fmax=re.findall(r";\s([.0-9]+)\s+MHz\s+;\s+clock_50",rpt_string)
                fmax=min(map(lambda x:float(x) , fmax))
                self.fmax=fmax
        if os.path.exists(synth_rpt):
            with open(synth_rpt) as f:
                rpt_string = f.read()
                self.cpu_prefit_size=int(re.findall(r"^;\s+\|riscV:riscv_0\|\s+; (\d+)",rpt_string,re.MULTILINE)[0])
        if os.path.exists(fit_rpt):
            with open(fit_rpt) as f:
                rpt_string = f.read()
                self.cpu_postfit_size=int(re.findall(r"^;\s+\|riscV:riscv_0\|\s+; (\d+)",rpt_string,re.MULTILINE)[0])
        with open(self.directory+"/summary.txt","w") as f:
            f.write('BRANCH_PREDICTION="%s"\n'   %self.branch_prediction)
            f.write('BTB_SIZE="%s"\n'            %self.btb_size)
            f.write('DIVIDE_ENABLE="%s"\n'       %self.divide_enable)
            f.write('INCLUDE_COUNTERS="%s"\n'    %self.multiply_enable)
            f.write('MULTIPLY_ENABLE="%s"\n'     %self.include_counters)
            f.write('SHIFTER_SINGLE_CYCLE="%s"\n'%self.shifter_single_cycle)
            f.write("FORWARD_ALU_ONLY=%s\n"      %self.fwd_alu_only)
            f.write( "fmax=%f\n"                 %self.fmax)
            f.write( "cpu_prefit_size=%d\n"      %self.cpu_prefit_size)
            f.write( "cpu_postfit_size=%d\n"     %self.cpu_postfit_size)

chart_script="""
function insert_chart(element_select,data) {


	 var margin = {top: 20, right: 15, bottom: 60, left: 60}
	 , width = 960 - margin.left - margin.right
	 , height = 500 - margin.top - margin.bottom;

         var xmin = d3.min(data, function(d) { return d[0]; });
         var xmax = d3.max(data, function(d) { return d[0]; });
         var xmarg = (xmax -xmin)*0.05;
         var xmin = xmin - xmarg
         var xmax = xmax + xmarg
	 var x = d3.scale.linear()
		  .domain([xmin,xmax])
		  .range([ 0, width ]);

         var ymin = d3.min(data, function(d) { return d[1]; });
         var ymax = d3.max(data, function(d) { return d[1]; });
         var ymarg = (ymax -ymin)*0.05;
         var ymin = ymin - ymarg
         var ymax = ymax + ymarg


	 var y = d3.scale.linear()
		  .domain([ymin,ymax])
		  .range([ height, 0 ]);

	 var chart = d3.select(element_select)
		  .append('svg:svg')
		  .attr('width', width + margin.right + margin.left)
		  .attr('height', height + margin.top + margin.bottom)
		  .attr('class', 'chart')

	 var main = chart.append('g')
		  .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')
		  .attr('width', width)
		  .attr('height', height)
		  .attr('class', 'main')

	 // draw the x axis
	 var xAxis = d3.svg.axis()
		  .scale(x)
		  .orient('bottom');

	 main.append('g')
		  .attr('transform', 'translate(0,' + height + ')')
		  .attr('class', 'main axis date')
		  .call(xAxis);

	 // draw the y axis
	 var yAxis = d3.svg.axis()
		  .scale(y)
		  .orient('left');

	 main.append('g')
		  .attr('transform', 'translate(0,0)')
		  .attr('class', 'main axis date')
		  .call(yAxis);

	 var g = main.append("svg:g");

	 g.selectAll("scatter-dots")
		  .data(data)
		  .enter().append("svg:circle")
		  .attr("cx", function (d,i) { return x(d[0]); } )
		  .attr("cy", function (d) { return y(d[1]); } )
		  .attr("r", 8)
		  .attr("class", function (d) { return d[2].split("_").slice(2).join(" "); } )
		  .append("svg:title").text(  function (d,i) { return d[2] } );
}
"""

check_boxes_html="""
<div >
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="btbsz0">    btbsz0      </input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="btbsz1">    btbsz1		</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="btbsz16">   btbsz16		</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="btbsz256">  tbsz256	</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="btbsz4096"> btbsz4096</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="div1">      div1				</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="mul1">      mul1				</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="count1">    count1		</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="pipe3">     pipe3			</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="ssc0">      ssc0				</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="ssc1">      ssc1				</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="ssc2">      ssc2				</input>
<input class="green-selector" type="checkbox"  onchange="toggle_checkbox(this)" name="fwd1">      fwd1          </input>
<script>
function toggle_checkbox(k) {

   var name =  d3.select(k).attr("name");
   var sel = d3.selectAll("."+name);
   if (d3.select(k).property("checked")){
      sel.style("fill","green");
   }else{
      sel.style("fill","steelblue");
   }
}
</script>
</div>
"""

def summarize_stats(systems):
    try:
        os.mkdir("summary")
    except:
        pass
    with open("summary/summary.html","w") as html:
        html.write("\n".join(("<!DOCTYPE html>",
                              "<html>",
                             "<head>",
                              "<title>Comparison of different build configurations</title>",
                              '<meta charset="UTF-8"> ',
                              '<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>',
                              '<script src="http://code.jquery.com/ui/1.11.3/jquery-ui.js"></script>',
                              '<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">',
                              '<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>'

                              #'<script src="http://www.kryogenix.org/code/browser/sorttable/sorttable.js"></script>',
                              '<script src="http://tablesorter.com/__jquery.tablesorter.min.js"></script>',
                              '<script type="text/javascript" src="http://mbostock.github.com/d3/d3.v2.js"></script>',

                              '<script >%s</script>'%chart_script,
                              "<style>                       ",
                              "	.chart {                     ",
                              "                              ",
                              "	}                            ",
                              "                              ",
                              "	.main text {                 ",
                              "	font: 10px sans-serif;       ",
                              "	}                            ",
                              "                              ",
                              "	.axis line, .axis path {     ",
                              "	shape-rendering: crispEdges; ",
                              "	stroke: black;               ",
                              "	fill: none;                  ",
                              "	}                            ",
                              "	circle {                     ",
                              "	fill: steelblue;             ",
                              "	}                            ",
                              "</style>                      ",
                              "<script>  ",
                              "  $(document).ready(function(){      ",
                              '      var tbl = $(".tablesorter");',
                              "      tbl.tablesorter() ",
                              "    $('.remove-row').click(function(){ ",
                              '       $($(this).closest("tr")).remove();',
                              "    });                              ",
                              "  });                                ",
                              "</script>                            ",
                              "</head>",
                              "<body>",
                              "<h2>Comparison of different build configurations</h2><br>\n",
                              "<table class=\"table table-striped table-bordered table-hover tablesorter\" style=\"text-align:center\">")))

        html.write("<thead><tr>")
        for th in ('','','branch prediction','btb size','multiply','divide',
                   'perfomance counters','pipeline stages','single cycle shift',
                   'fwd alu only','prefit size','postfit size','FMAX','DMIPS','DMIPS/MHz','DMIPS/1000LUT (post-fit)'):
            html.write('<th>%s</th>'%th)
        html.write("</tr></thead><tbody>\n")
        dhry_data=[]
        fmax_data=[]
        for sys in systems:
            try:
                fmax_data.append([sys.cpu_postfit_size,sys.fmax,sys.directory])
                dmips_per_mhz=((5*1000000./1757)/int(sys.dhrystones))
                dmips=dmips_per_mhz*sys.fmax
                dmips_per_lut=dmips*1000/sys.cpu_postfit_size;
                dhry_data.append([sys.cpu_postfit_size,1000./dmips,sys.directory])

                dmips_per_mhz="%.3f" % dmips_per_mhz
                dmips="%.3f"% dmips
                dmips_per_lut="%.3f"% dmips_per_lut

            except Exception as e:
                dmips_per_mhz=""
                dmips=""
                dmips_per_lut=sys.dhrystones


            button_html='<button class="btn btn-default remove-row"><span class="glyphicon glyphicon-remove" aria-hidden=true></span></button>'
            html.write("<tr>")
            html.write("<td>%s</td>" % button_html)
            html.write("<td>%s</td>"%str(sys.directory))
            html.write("<td>%s</td>"%str(sys.branch_prediction))
            html.write("<td>%s</td>"%str(sys.btb_size if sys.branch_prediction == "true" else "N/A"))
            html.write("<td>%s</td>"%str(sys.multiply_enable))
            html.write("<td>%s</td>"%str(sys.divide_enable))
            html.write("<td>%s</td>"%str(sys.include_counters))
            html.write("<td>%s</td>"%str(sys.pipeline_stages))
            html.write("<td>%s</td>"%str(sys.shifter_single_cycle if sys.multiply_enable == "0" else "N/A"))
            html.write("<td>%s</td>"%str(sys.fwd_alu_only))
            html.write("<td>%s</td>"%str(sys.cpu_prefit_size))
            html.write("<td>%s</td>"%str(sys.cpu_postfit_size))
            html.write("<td>%s</td>"%str(sys.fmax))
            html.write("<td>%s</td>"%str(dmips))
            html.write("<td>%s</td>"%str(dmips_per_mhz))
            html.write("<td>%s</td>"%str(dmips_per_lut))

            html.write("</tr>\n")
        html.write("</tbody></table>\n")
        html.write(check_boxes_html);
        def add_chart(title,data):
            id=hash(title)
            id = id if id >0 else -id
            if len(data):
                html.write("<div id=\"id_%x\"><h3>%s</h3></div>\n" % (id,title))
                html.write("<script>\n insert_chart(\"#id_%x\",%s);\n</script>" % (id,str(data)))
        add_chart("LUT Count vs Execution Time (1000/DMIPS)",dhry_data)
        add_chart("LUT Count vs FMax", fmax_data)
        html.write("</body></html>\n")

SYSTEMS=[]

if 0:
    SYSTEMS=[ system(branch_prediction="false",
                     btb_size="1",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="1",
                     shifter_single_cycle="0",
                     pipeline_stages="3",
                     fwd_alu_only="1"),
              system(branch_prediction="false",
                     btb_size="1",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="4",
                     fwd_alu_only="1"),
              system(branch_prediction="true",
                     btb_size="4096",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="4",
                     fwd_alu_only="1"),
              system(branch_prediction="true",
                     btb_size="256",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="4",
                     fwd_alu_only="1"),
              system(branch_prediction="false",
                     btb_size="1",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="0",
                     shifter_single_cycle="1",
                     pipeline_stages="4",
                     fwd_alu_only="1"),
              system(branch_prediction="true",
                     btb_size="256",
                     divide_enable="0",
                     multiply_enable="0",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="3",
                     fwd_alu_only="1"),
              system(branch_prediction="false",
                     btb_size="256",
                     divide_enable="1",
                     multiply_enable="1",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="3",
                     fwd_alu_only="1"),
              system(branch_prediction="true",
                     btb_size="4096",
                     divide_enable="1",
                     multiply_enable="1",
                     include_counters="1",
                     shifter_single_cycle="0",
                     pipeline_stages="3",
                     fwd_alu_only="1"),
              system(branch_prediction="false",
                     btb_size="256",
                     divide_enable="1",
                     multiply_enable="1",
                     include_counters="0",
                     shifter_single_cycle="0",
                     pipeline_stages="4",
                     fwd_alu_only="1"),
              system(branch_prediction="true",
                     btb_size="4096",
                     divide_enable="1",
                     multiply_enable="1",
                     include_counters="1",
                     shifter_single_cycle="0",
                     pipeline_stages="4",
                     fwd_alu_only="1"),

      ]
else:

    for bp in ["false","true"]:
        for btb_size in ["1","16","256","4096"]:
            if bp== "false" and btb_size != "1":
                continue;
            for mul in ["0","1"]:
                for div in ["0","1"]:
                    if div == "1" and mul == '0':
                        continue;
                    for ic in ["0","1"]:
                        for ssc in ["0","1","2"]:
                            if mul == '1' and ssc != '0':
                                continue;
                            for ps in ["3","4"]:
                                SYSTEMS.append(system(branch_prediction=bp,
                                                      btb_size=btb_size,
                                                      divide_enable=div,
                                                      multiply_enable=mul,
                                                      include_counters=ic,
                                                      shifter_single_cycle=ssc,
                                                      pipeline_stages=ps,
                                                      fwd_alu_only="1"))


if __name__ == '__main__':

    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('-s','--stats-only',dest='stats_only',action='store_true',default=False)
    parser.add_argument('-d','--skip-dhrysone',dest='skip_dhrystone',action='store_true',default=False)
    parser.add_argument('-n','--no-stats',dest='no_stats',action='store_true',default=False)
    parser.add_argument('-t','--build-target',dest='build_target',default='all',help='Target to run with make command')
    parser.add_argument('-q','--use-qsub',dest='use_qsub',action='store_true',default=False, help='Use grid-engine to build systems')
    args=parser.parse_args()

    devnull=open(os.devnull,"w")
    processes=[]

    if not os.path.exists('sim/vblox1/simulation/vblox1.vhd'):
        with pushd('sim'):
            print "generating simulation files"
            subprocess.call( "qsys-generate --simulation=vhdl vblox1.qsys;"+
                                        " cd vblox1/simulation/submodules/;"+
                                        "ln -sf ../../../../*.vhd .",shell=True,
                                       stdout=devnull,stderr=devnull)

    for s in SYSTEMS:
        s.create_build_dir()

    for s in SYSTEMS:
        if not args.stats_only:
            processes.append(
                s.build(args.use_qsub,args.build_target))
        if not args.no_stats and not args.skip_dhrystone:
            processes.append(
                s.run_dhrystone_sim(args.use_qsub))

        while len(processes) > 25:
            processes = [ p for p in processes if p.poll() == None ]
            if len(processes) > 25:
                time.sleep(5)

    for p in processes:
        p.wait()

    for s in SYSTEMS:
        if not args.no_stats:
            s.get_build_stats()
            s.get_dhrystone_stats()
    if not args.no_stats:
        summarize_stats(SYSTEMS)
