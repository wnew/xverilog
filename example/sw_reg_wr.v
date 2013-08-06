//============================================================================//
//                                                                            //
//      Software Register read and write on wishbone bus                      //
//                                                                            //
//      Module name: sw_reg_wr                                                //
//      Desc: Software register with read and write on wishbone interface     //
//            and read only on fabric interface                               //
//      Date: Dec 2011                                                        //
//      Developer: Wesley New                                                 //
//      Licence: GNU General Public License ver 3                             //
//      Notes: To avoid race conditions the software reg is split into 2      //
//             different modules                                              //
//                                                                            //
//============================================================================//
//                                _________                                   //
//                  read & write |         | read only                        //
//               SW <----------> |   Reg   | --------> Fabric                 //
//                               |_________|                                  //
//                                                                            //
//============================================================================//


module sw_reg_wr #(
      //================
      // parameters
      //================
      parameter C_BASEADDR      = 32'h00000000,
      parameter C_HIGHADDR      = 32'h0000000F,
      parameter C_WB_DATA_WIDTH = 32,
      parameter C_WB_ADDR_WIDTH = 1,
      parameter C_BYTE_EN_WIDTH = 4
   ) (
      slave wb, 
      //================
      // fabric ports
      //================
      input         fabric_clk,
      output        fabric_data_out
   );
 
   wire a_match = wb.adr_i >= C_BASEADDR && wb.adr_i <= C_HIGHADDR;
 
   //================
   // register buffer 
   //================
   reg [31:0] reg_buffer;
 
   //================
   // wb control
   //================
   reg wb.ack_reg;
   assign wb.ack_o = wb.ack_reg;
   always @(posedge wb.clk_i)
   begin
      wb.ack_reg <= 1'b0;
      if (wb.rst_i)
      begin
       //
      end
      else
      begin
         if (wb.stb_i && wb.cyc_i)
         begin
            wb.ack_reg <= 1'b1;
         end
      end
   end
 
   //================
   // wb write
   //================
   always @(posedge wb.clk_i)
   begin
      register_doneR  <= register_done;
      register_doneRR <= register_doneR;
      // reset
      if (wb.rst_i)
      begin
         reg_buffer <= 32'd0;
         register_ready <= 1'b0;
      end
      else
      begin
         if (a_match && wb.stb_i && wb.cyc_i && wb.we_i)
         begin
            register_ready <= 1'b1;
            case (wb.adr_i[6:2])
               // byte enables
               5'h0:
               begin
                  if (wb.sel_i[0])
                     reg_buffer[7:0] <= wb.dat_i[7:0];
                  if (wb.sel_i[1])
                     reg_buffer[15:8] <= wb.dat_i[15:8];
                  if (wb.sel_i[2])
                     reg_buffer[23:16] <= wb.dat_i[23:16];
                  if (wb.sel_i[3])
                     reg_buffer[31:24] <= wb.dat_i[31:24];
               end
            endcase
         end
      end
      if (register_doneRR)
      begin
         register_ready <= 1'b0;
      end
   end
 
   //================
   // wb read
   //================
   reg [31:0] wb.dat_o_reg;
   assign wb.dat_o = wb.dat_o_reg;
 
   always @(*)
   begin
      if(~wb.we_i)
      begin
         case (wb.adr_i[6:2])
            5'h0:   
               wb.dat_o_reg <= reg_buffer;
            default:
               wb.dat_o_reg <= 32'b0;
         endcase
      end
   end
 
   
   //================
   // fabric read
   //================
   reg [31:0] fabric_data_out_reg; 
   /* Handshake signal from OPB to application indicating data is ready to be latched */
   reg register_ready;
   reg register_readyR; 
   reg register_readyRR; 
   /* Handshake signal from application to OPB indicating data has been latched */
   reg register_done;
   reg register_doneR;
   reg register_doneRR;
   assign fabric_data_out = fabric_data_out_reg; 
  
   always @(posedge fabric_clk) 
   begin 
      // registering for clock domain crossing  
      register_readyR  <= register_ready; 
      register_readyRR <= register_readyR; 
  
      if (!register_readyRR)
      begin 
         register_done <= 1'b0; 
      end 
  
      if (register_readyRR)
      begin 
         register_done <= 1'b1; 
         fabric_data_out_reg <= reg_buffer; 
      end 
   end

endmodule
