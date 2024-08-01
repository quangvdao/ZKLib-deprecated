import Batteries.Data.UInt
import Jolt.ConstraintSystem.Constants
import Jolt.RiscV.ISA

/-!
  # Trace model for Jolt
-/

namespace Jolt

open RiscV

structure ELFInstruction where
  address : UInt64
  opcode : RV32IM.Instr
  rs1 : Option UInt64
  rs2 : Option UInt64
  rd : Option UInt64
  imm : Option UInt32
  virtualSequenceIndex : Option USize
deriving Repr, Inhabited

structure RegisterState where
  rs1Value : Option UInt64
  rs2Value : Option UInt64
  rdValue : Option UInt64
deriving Repr, Inhabited, DecidableEq

section Memory

inductive MemoryState where
  | Read (address : UInt64) (value : UInt64)
  | Write (address : UInt64) (value : UInt64)
deriving Repr, Inhabited

inductive MemoryOp where
  | Read (address : UInt64)
  | Write (address : UInt64) (value : UInt64)
deriving Repr, Inhabited

structure MemoryLayout where
  maxInputSize : UInt64
  maxOutputSize : UInt64
deriving Repr, Inhabited

def MemoryLayout.ramWitnessOffset (m : MemoryLayout) : UInt64 :=
  (REGISTER_COUNT + m.maxInputSize + m.maxOutputSize + 1).nextPowerOfTwo

def MemoryLayout.inputStart (m : MemoryLayout) : UInt64 :=
  RAM_START_ADDRESS - m.ramWitnessOffset + REGISTER_COUNT

def MemoryLayout.inputEnd (m : MemoryLayout) : UInt64 :=
  m.inputStart + m.maxInputSize

def MemoryLayout.outputStart (m : MemoryLayout) : UInt64 :=
  m.inputEnd + 1

def MemoryLayout.outputEnd (m : MemoryLayout) : UInt64 :=
  m.outputStart + m.maxOutputSize

def MemoryLayout.panic (m : MemoryLayout) : UInt64 :=
  m.outputEnd + 1

end Memory

structure RVTraceRow where
  instruction : ELFInstruction
  registerState : RegisterState
  memoryState : Option MemoryState
  adviceValue : Option UInt64
deriving Repr, Inhabited

structure BytecodeRow where
  address : USize
  bitflags : UInt64
  rs1 : UInt64
  rs2 : UInt64
  rd : UInt64
  imm : UInt64
deriving Repr, Inhabited

-- TODO: Define `InstructionSet` and `SubtableSet`

structure JoltTraceStep (InstructionSet : Type) where
  instructionLookup : Option InstructionSet
  bytecodeRow : BytecodeRow
  memoryOps : Fin MEMORY_OPS_PER_INSTRUCTION → MemoryOp
deriving Inhabited

structure JoltDevice where
  inputs : Array UInt8
  outputs : Array UInt8
  panic : Bool
  memoryLayout : MemoryLayout
deriving Repr, Inhabited

end Jolt
